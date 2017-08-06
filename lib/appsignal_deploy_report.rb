require 'date'
require_relative 'appsignal_report'

class AppsignalDeployReport < AppsignalReport
  def generate
    @report = {}
    @last_deploy_time = DateTime.parse(last_deploy[:created_at]).to_time
    @report.merge(last_deploy_time: @last_deploy_time)

    metrics = perform_api_request(metrics_uri)
    @report.merge(from: metrics[:from], to: metrics[:to])

    data = split_metrics(metrics[:data])
    %i(before after).each do |key|
      @report[key] = {
        data_points: data[key].size,
        error_rate: get_average(data[key], :ex_rate),
        response_time: get_average(data[key], :mean),
        hourly_throughput: get_average(data[key], :count),
      }
    end
    @report[:diff] = generate_diff

    @report[:diff]
  end

  def generate_diff
    {
      data_points: abs_diff(:data_points),
      data_points_pct: pct_diff(:data_points),
      error_rate: abs_diff(:error_rate),
      error_rate_pct: pct_diff(:error_rate),
      response_time: abs_diff(:response_time),
      response_time_pct: pct_diff(:response_time),
      hourly_throughput: abs_diff(:hourly_throughput),
      hourly_throughput_pct: pct_diff(:hourly_throughput),
    }
  end

  def abs_diff(key)
    @report[:after][key] - @report[:before][key]
  end

  def pct_diff(key)
    abs_diff(key).fdiv(@report[:before][key])
  end

  def split_metrics(metrics)
    metrics.each_with_object(before: [], after: []) do |row, hash|
      if row[:timestamp] < @last_deploy_time.to_i
        hash[:before] << row
      else
        hash[:after] << row
      end
    end
  end

  private

  def metrics_uri
    # puts "\nPARAMS\n"
    query = URI.encode_www_form(#p
      token: api_token,
      from: format_time(@last_deploy_time - 3600), # one hour before last deploy
      to: format_time(@last_deploy_time + 3600), # one hour after last deploy
      'fields[]': %i(mean count ex_rate)
    )
    URI("#{base_uri}/graphs.json?#{query}")
  end

  def format_time(time)
    time.strftime('%FT%T%:z')
  end

  def last_deploy
    @last_deploy = perform_api_request(last_deploy_marker_uri)[:markers].first
    # { created_at: '2017-08-06T19:14:53.405+02:00' }
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
