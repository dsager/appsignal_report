class AppsignalReport
  attr_reader :from

  def initialize(from: nil)
    @from = from || (Date.today - 7)
    puts uri
  end

  def uri
    "https://appsignal.com/api/#{app_id}/namespaces/web.json" \
      "?token=#{api_token}" \
      "&from=#{from.iso8601}"
  end

  def api_token
    ENV['APPSIGNAL_API_TOKEN']
  end

  def app_id
    ENV['APPSIGNAL_APP_ID']
  end
end
