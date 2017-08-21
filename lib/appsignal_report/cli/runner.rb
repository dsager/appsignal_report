module AppsignalReport
  module CLI
    class Runner
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def run
        report.generate
        options[:slack_webhook] ? post_to_slack : print_json
      end

      def report
        @report ||= report_class.new(
          api_token: options[:api_token],
          app_id: options[:app_id],
          app_name: options[:app_name]
        )
      end

      private

      def report_class
        case options[:type]
        when :deploy
          AppsignalReport::DeployReport
        when :weekly
          AppsignalReport::WeeklyReport
        else
          raise ArgumentError, "invalid report type: '#{options[:type]}'"
        end
      end


      def print_json
        puts report.report.to_json
      end

      def post_to_slack
        message = AppsignalReport::SlackMessage.new(
          report: report,
          webhook_url: options[:slack_webhook]
        )
        puts message.post
      end
    end
  end
end
