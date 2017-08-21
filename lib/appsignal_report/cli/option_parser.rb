module AppsignalReport
  module CLI
    class OptionParser
      def initialize(additional_options = {})
        @additional_options = additional_options
      end

      def parse
        option_parser.parse!
      end

      def options
        @options ||= {
          slack_webhook: nil,
          app_id: nil,
          app_name: nil,
        }.merge(@additional_options)
      end

      private

      def option_parser
        ::OptionParser.new do |parser|
          parser.banner =
            'Usage: APPSIGNAL_API_TOKEN=XXX ./bin/appsignal_report_* [options]'
          parser.separator ''
          parser.separator 'Specific options:'
          parser.on('-i ID',
                    '--app-id ID',
                    String,
                    'Specify Appsignal App Id') do |id|
            options[:app_id] = id
          end
          parser.on('-n NAME',
                    '--app-name NAME',
                    String,
                    'Specify a name for the Appsignal App') do |name|
            options[:app_name] = name
          end
          parser.on('-s WEBHOOK_URL',
                    '--slack WEBHOOK_URL',
                    String,
                    'Post the report to a Slack Webhook') do |url|
            options[:slack_webhook] = url
          end
          parser.separator ''
          parser.separator 'Common options:'
          parser.on_tail('-h', '--help', 'Show this message') do
            puts parser
            exit
          end
        end
      end
    end
  end
end
