require_relative 'appsignal_report'
#
# Weekly Report
#
# Compare metrics of the last week with the one before that:
# - Error Rate
# - Response Time
# - Throughput
#
class AppsignalWeeklyReport < AppsignalReport
  def generate
    @report = {
      title: title,
      now: Time.now.utc,
      one_week_ago: (Time.now - (3600 * 24 * 7)).utc,
      two_weeks_ago: (Time.now - (3600 * 24 * 14)).utc,
    }
    process_metrics
  end

  private

  def report_split_time
    report[:one_week_ago]
  end

  # @return [URI]
  def metrics_uri
    query = URI.encode_www_form(
      token: api_token,
      from: report[:two_weeks_ago].iso8601,
      'fields[]': %i(mean count ex_rate)
    )
    URI("#{base_uri}/graphs.json?#{query}")
  end
end
