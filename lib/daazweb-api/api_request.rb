module DaazwebApi
  class APIRequest

    def initialize(builder: nil)
      @request_builder = builder
    end

    def post(params: nil, headers: nil, body: {})
      validate_api_key
      begin
        response = self.rest_client.post do |request|
          configure_request(request: request, params: params, headers: headers, body: body)
        end
        parse_response(response)
      rescue => e
        handle_error(e)
      end
    end

    def get(params: nil, headers: nil, body: {})
      validate_api_key

      begin
        response = self.rest_client.get do |request|
          configure_request(request: request, params: params, headers: headers, body: body)
        end
        parse_response(response)
      rescue => e
        handle_error(e)
      end
    end

    protected

    # Convenience accessors

    def access_token
      @request_builder.access_token
    end

    def timeout
      @request_builder.timeout
    end

    def open_timeout
      @request_builder.open_timeout
    end

    def proxy
      @request_builder.proxy
    end

    def adapter
      @request_builder.faraday_adapter
    end

    def symbolize_keys
      @request_builder.symbolize_keys
    end

    # Helpers

    def handle_error(error)
      error_params = {}

      begin
        if error.is_a?(Faraday::ClientError) && error.response
          error_params[:status_code] = error.response[:status]
          error_params[:raw_body] = error.response[:body]

          parsed_response = MultiJson.load(error.response[:body], symbolize_keys: symbolize_keys)

          if parsed_response
            error_params[:body] = parsed_response

            title_key = symbolize_keys ? :title : "title"
            detail_key = symbolize_keys ? :detail : "detail"

            error_params[:title] = parsed_response[title_key] if parsed_response[title_key]
            error_params[:detail] = parsed_response[detail_key] if parsed_response[detail_key]
          end

        end
      rescue MultiJson::ParseError
      end

      error_to_raise = DaazwebApiError.new(error.message, error_params)

      raise error_to_raise
    end

    def configure_request(request: nil, params: nil, headers: nil, body: nil)
      if request
        request.params.merge!(params) if params
        request.headers = {}
        request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        request.headers['Authorization'] = "Bearer #{self.access_token}"
        request.headers['User-Agent'] = "DaazwebApi/#{DaazwebApi::VERSION} Ruby gem"
        request.headers.merge!(headers) if headers
        request.body = body.try(:to_query)
        request.options.timeout = self.timeout
        request.options.open_timeout = self.open_timeout
      end
    end

    def rest_client
      client = Faraday.new(self.api_url, proxy: self.proxy) do |faraday|
        faraday.response :raise_error
        faraday.adapter adapter
        if @request_builder.debug
          faraday.response :logger, @request_builder.logger, bodies: true
        end
      end
      client
    end

    def parse_response(response)
      parsed_response = nil

      if response.body && !response.body.empty?
        begin
          headers = response.headers
          body = MultiJson.load(response.body, symbolize_keys: symbolize_keys)
          parsed_response = Response.new(headers: headers, body: body)
        rescue MultiJson::ParseError
          error_params = { title: "UNPARSEABLE_RESPONSE", status_code: 500 }
          error = DaazwebApiError.new("Unparseable response: #{response.body}", error_params)
          raise error
        end
      end

      parsed_response
    end

    def validate_api_key
      unless self.access_token
        raise DaazwebApi::DaazwebApiError, "You must set an access_token to making a call #{DaazwebApi::API_ENDPOINT}"
      end
    end

    def api_url
      base_api_url + @request_builder.path + "/"
    end

    def base_api_url
      "#{DaazwebApi::API_ENDPOINT}/api/"
    end
  end
end
