class AppsignalReport
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
    puts "\nAppSignal - #{self.class.name.sub('Appsignal', '')}\n"
    generate
    report.each { |key, value| puts format('%30s: %s', key, value) }
    puts "\n\n"
  end

  # To be defined by subclass, should set the instance var @report.
  # @return [Hash]
  def generate; end

  private

  # @param [Array[Hash]] data
  # @param [Symbol] field
  # @return [Float]
  def get_average(data, field)
    values = data.map { |row| row[field] }
    values.inject(0, :+).fdiv(values.size)
  end

  # @return [String]
  def base_uri
    "https://appsignal.com/api/#{app_id}"
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
      raise StandardError, "[API ERROR] #{response.code} - #{response.message}"
    end
  end
end
