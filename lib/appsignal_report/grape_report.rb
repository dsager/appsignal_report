module AppsignalReport
  #
  # Grape Report
  #
  # Get a list of all endpoints mounted in a ruby-grape application. Then get
  # a list of endpoint-metrics from AppSignal for the last 30 days. Assuming
  # that endpoints which are not within the AppSignal-list did not record any
  # traffic, potentially inactive endpoints are reported.
  #
  # Caution: oftentimes "inactive" endpoints are just endpoints with little
  # usage and you still want to keep them. So don't delete anything without
  # double-checking at least three times :)
  #
  class GrapeReport < BaseReport
    def generate
      api_response = perform_api_request(metrics_uri)
      @report = {
        title: title,
      }
    end

    private

    # @return [String]
    def info_message
      <<-txt
Found 449 defined endpoints in grape.
Got data for 423 endpoints from AppSignal.
This makes for 26 potentially (!!!) inactive endpoints.
      txt
    end

    # @return [URI]
    def metrics_uri
      one_hour = 3600 # seconds
      query = URI.encode_www_form(
        token: api_token,
        from: 1.month.ago.iso8601,
        'fields[]': %i(mean count ex_rate)
      )
      URI("#{base_uri}/namespaces/web.json?#{query}")
    end

    ##############################
    def samples
      response['actions'].map { |action| action['name'].chomp('/') }
    end
    ##############################
  end
end
