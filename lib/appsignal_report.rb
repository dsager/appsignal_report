class AppsignalReport
  attr_reader :api_token, :app_id

  # @param [String] api_token API token, find it here:
  #                           <https://appsignal.com/users/edit>
  # @param [String] app_id    Application ID, visible in the URL when your
  #                           application is opened on Appsignal.com
  def initialize(api_token:, app_id:)
    @api_token = api_token
    @app_id = app_id
  end

  # @return [Hash]
  def generate
    summarize(
      perform_api_request(
        uri(
          token: api_token,
          timeframe: :week,
          'fields[]': %i(mean count ex_rate)
        )
      )
    )
  end

  def summarize(data)
    {
      from: data[:from],
      to: data[:to],
      average_error_rate: get_average(data[:data], :ex_rate),
      average_response_time: get_average(data[:data], :mean),
      average_throughput: get_average(data[:data], :count),
    }
  end

  def get_average(data, field)
    values = data.map { |row| row[field] }
    values.inject(0, :+).fdiv(values.size)
  end

  # @param [Hash] params
  def uri(params = {})
    query = URI.encode_www_form(params)
    URI("https://appsignal.com/api/#{app_id}/graphs.json?#{query}")
  end

  # @param [URI] uri
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
