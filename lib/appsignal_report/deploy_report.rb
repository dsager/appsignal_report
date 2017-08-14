module AppsignalReport
  #
  # Deploy Report
  #
  # Compare metrics of one hour before and after the last deploy:
  # - Error Rate
  # - Response Time
  # - Throughput
  #
  class DeployReport < BaseReport
    def generate
      @report = {
        title: title,
        last_deploy_time: Time.parse(last_deploy[:created_at]).utc,
      }
      process_metrics
    end

    private

    # @return [Time|nil]
    def report_split_time
      report[:last_deploy_time]
    end

    # @return [Boolean]
    def timestamp_in_grace_period?(timestamp)
      grace_period = 10 * 60
      (timestamp - report[:last_deploy_time].to_time.to_i).abs < grace_period
    end

    # @return [URI]
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

    # @return [Hash]
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
end
