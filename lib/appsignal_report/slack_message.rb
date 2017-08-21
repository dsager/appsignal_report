module AppsignalReport
  class SlackMessage
    attr_reader :report, :webhook_uri

    def initialize(report:, webhook_url:)
      @report = report
      @webhook_uri = URI(webhook_url)
    end

    # @return [Hash]
    def post
      http = Net::HTTP.new(webhook_uri.host, webhook_uri.port)
      http.use_ssl = true

      post =
        Net::HTTP::Post.new(webhook_uri, 'Content-Type' => 'application/json')
      post.body = payload.to_json
      response = http.request(post)

      unless response.is_a? Net::HTTPSuccess
        raise StandardError,
              "[API ERROR] #{response.code} - #{response.message}"
      end
    end

    # @return [Hash]
    def payload
      {
        text: report.title,
        attachments: attachment_messages.map { |message| { text: message } },
      }
    end

    def attachment_messages
      [
        ":information_source: #{report.report[:messages][:info]}",
        "#{error_rate_icon} #{report.report[:messages][:error_rate]}",
        "#{response_time_icon} #{report.report[:messages][:response_time]}",
        "#{throughput_icon} #{report.report[:messages][:throughput]}",
      ]
    end

    def error_rate_icon
      report.report[:diff][:error_rate].negative? ? ':+1:' : ':-1:'
    end

    def response_time_icon
      report.report[:diff][:response_time].negative? ? ':+1:' : ':-1:'
    end

    def throughput_icon
      up_down =
        report.report[:diff][:throughput].negative? ? 'downwards' : 'upwards'
      ":chart_with_#{up_down}_trend:"
    end
  end
end
