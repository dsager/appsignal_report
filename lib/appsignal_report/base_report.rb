module AppsignalReport
  #
  # Report base class, defines the general flow and helper methods used by the
  # specific report classes.
  #
  class BaseReport
    attr_reader :api_token, :app_id, :report

    # @param [String] api_token API token, find it here:
    #                           <https://appsignal.com/users/edit>
    # @param [String] app_id    Application ID, visible in the URL when your
    #                           application is opened on Appsignal.com
    def initialize(api_token:, app_id:)
      @api_token = api_token
      @app_id = app_id
      @report = {}
    end

    def print
      puts "\n#{title}\n"
      generate
      report.each { |key, value| puts format('%30s: %s', key, value) }
      puts "\n\n"
    end

    # @return [Hash]
    def slack_message
      {
        text: title,
        attachments: slack_status_messages.map { |message| { text: message } },
      }
    end

    # To be defined by subclass, should set the instance var @report.
    # @return [Hash]
    def generate
      raise NotImplementedError
    end

    private

    def title
      title = self.class.name.split('::').last.split(/(?=[A-Z])/).join(' ')
      "AppSignal #{title}"
    end

    def process_metrics
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
      The #{field.to_s.sub('_', ' ')}
      #{report[:diff][field].positive? ? 'increased' : 'decreased'}
      by #{report[:diff][field].abs.round(2)}#{unit}
      (from #{report[:before][field].round(2)}#{unit}
      to #{report[:after][field].round(2)}#{unit}, that is a change of
      #{(report[:diff][:"#{field}_pct"] * 100).round(2)}%).
      txt
    end

    # @param [Array[Hash]] data
    # @param [Symbol] field
    # @return [Float]
    def get_average(data, field)
      values = data.map { |row| row[field] }
      values.inject(0, :+).fdiv(values.size)
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
      split_timestamp = report_split_time.to_time.to_i
      samples.each_with_object(before: [], after: []) do |row, hash|
        next if timestamp_in_grace_period?(row[:timestamp])
        if row[:timestamp] < split_timestamp
          hash[:before] << row
        else
          hash[:after] << row
        end
      end
    end

    def balance_samples(samples)
      sample_size = [samples[:before].size, samples[:after].size].min
      samples[:before] = samples[:before].last(sample_size)
      samples[:after] = samples[:after].first(sample_size)
      samples
    end

    def report_split_time
      raise NotImplementedError
    end

    def timestamp_in_grace_period?(_)
      false
    end

    # @return [String]
    def base_uri
      "https://appsignal.com/api/#{app_id}"
    end

    # @return [URI]
    def metrics_uri
      raise NotImplementedError
    end

    # @return [Hash]
    def perform_api_request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      response = http.request(
        Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
      )
      if response.is_a? Net::HTTPSuccess
        JSON.parse(response.body, symbolize_names: true)
      else
        raise StandardError,
              "[API ERROR] #{response.code} - #{response.message}"
      end
    end
  end
end
