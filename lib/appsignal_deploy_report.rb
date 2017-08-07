require 'time'
require_relative 'appsignal_report'

class AppsignalDeployReport < AppsignalReport
  def generate
    @report = { last_deploy_time: Time.parse(last_deploy[:created_at]).utc }
    api_response = perform_api_request(metrics_uri)
    data = balance_samples(gather_samples(api_response[:data]))
    %i(before after).each do |key|
      @report[key] = {
        data_points: data[key].size,
        error_rate: get_average(data[key], :ex_rate),
        response_time: get_average(data[key], :mean),
        hourly_throughput: get_average(data[key], :count),
      }
    end
    @report.merge!(
      data_samples_from: Time.at(data[:before].first[:timestamp]).utc,
      data_samples_to: Time.at(data[:after].last[:timestamp]).utc,
      diff: generate_diff,
    )
    @report[:messages] = generate_messages
    report
  end

  def slack_message
    {
      text: 'AppSignal Deploy Report',
      attachments: slack_status_messages.map { |message| { text: message } },
    }
  end

  private

  def slack_status_messages
    [
      ":clock4: The deploy finished at #{report[:last_deploy_time]}",
      [
        report[:diff][:error_rate].negative? ? ':+1:' : ':-1:',
        report[:messages][:error_rate]
      ].join(' '),
      [
        report[:diff][:response_time].negative? ? ':+1:' : ':-1:',
        report[:messages][:response_time]
      ].join(' '),
      [
        ":chart_with_#{report[:diff][:hourly_throughput].negative? ? 'downwards' : 'upwards'}_trend:",
        report[:messages][:hourly_throughput]
      ].join(' '),
    ]
  end

  def generate_messages
    {
      error_rate: metric_message(:error_rate, '%'),
      response_time: metric_message(:response_time, 'ms'),
      hourly_throughput: metric_message(:hourly_throughput, ' req/h'),
    }
  end

  def metric_message(field, unit = '')
    <<-txt.split.join(' ')
      After the deploy, the #{field.to_s.sub('_', ' ')}
      #{report[:diff][field].positive? ? 'increased' : 'decreased'}
      by #{report[:diff][field].abs.round(2)}#{unit}
      (from #{report[:before][field].round(2)}#{unit}
      to #{report[:after][field].round(2)}#{unit}, that is a change of
      #{(report[:diff][:"#{field}_pct"] * 100).round(2)}%).
    txt
  end

  def generate_diff
    {
      error_rate: abs_diff(:error_rate),
      error_rate_pct: pct_diff(:error_rate),
      response_time: abs_diff(:response_time),
      response_time_pct: pct_diff(:response_time),
      hourly_throughput: abs_diff(:hourly_throughput),
      hourly_throughput_pct: pct_diff(:hourly_throughput),
    }
  end

  def abs_diff(key)
    report[:after][key] - report[:before][key]
  end

  def pct_diff(key)
    abs_diff(key).fdiv(report[:before][key])
  end

  def gather_samples(samples)
    samples.each_with_object(before: [], after: []) do |row, hash|
      next if timestamp_in_grace_period?(row[:timestamp])
      if row[:timestamp] < report[:last_deploy_time].to_time.to_i
        hash[:before] << row
      else
        hash[:after] << row
      end
    end
  end

  def timestamp_in_grace_period?(timestamp)
    grace_period = 10 * 60
    (timestamp - report[:last_deploy_time].to_time.to_i).abs < grace_period
  end

  def balance_samples(samples)
    sample_size = [samples[:before].size, samples[:after].size].min
    samples[:before] = samples[:before].last(sample_size)
    samples[:after] = samples[:after].first(sample_size)
    samples
  end

  def metrics_uri
    one_hour = 3600 # seconds
    query = URI.encode_www_form(
      token: api_token,
      from: (report[:last_deploy_time] - one_hour).iso8601,
      to: (report[:last_deploy_time] + one_hour).iso8601,
      'fields[]': %i(mean count ex_rate)
    )
    URI("#{base_uri}/graphs.json?#{query}")
  end

  def last_deploy
    @last_deploy = perform_api_request(last_deploy_marker_uri)[:markers].first
  end

  # @return [URI]
  def last_deploy_marker_uri
    query = URI.encode_www_form(
      token: api_token,
      kind: :deploy,
      limit: 1
    )
    URI("#{base_uri}/markers.json?#{query}")
  end
end
