require_relative 'appsignal_report'
#
# Weekly Report
#
# Calculates the average values over the last week for a few metrics:
# - Error Rate
# - Response Time
# - Hourly Throughput
#
class AppsignalWeeklyReport < AppsignalReport
  def generate
    @report = parse_api_response(perform_api_request(uri))
  end

  private

  # @return [Hash]
  # @param [Object] data
  def parse_api_response(data)
    {
      from: data[:from],
      to: data[:to],
      error_rate: get_average(data[:data], :ex_rate),
      response_time: get_average(data[:data], :mean),
      hourly_throughput: get_average(data[:data], :count),
    }
  end

  # @return [URI]
  def uri
    query = URI.encode_www_form(
      token: api_token,
      timeframe: :week,
      'fields[]': %i(mean count ex_rate)
    )
    URI("#{base_uri}/graphs.json?#{query}")
  end
end
