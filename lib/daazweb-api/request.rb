module DaazwebApi
  class Request
    attr_accessor :access_token, :timeout, :open_timeout, :proxy, :faraday_adapter, :symbolize_keys,
                  :debug, :logger, :test

    DEFAULT_TIMEOUT = 60
    DEFAULT_OPEN_TIMEOUT = 60

    def initialize(access_token: nil, timeout: nil, open_timeout: nil, proxy: nil,
                   faraday_adapter: nil, symbolize_keys: false, debug: false, logger: nil, test: false)

      @path_parts = []
      @access_token = access_token || self.class.access_token || DaazwebApi.generate_access_token.try(:dig, "access_token")
      @timeout = timeout || self.class.timeout || DEFAULT_TIMEOUT
      @open_timeout = open_timeout || self.class.open_timeout || DEFAULT_OPEN_TIMEOUT
      @proxy = proxy || self.class.proxy || ENV['DAAZWEB_API_PROXY']
      @faraday_adapter = faraday_adapter || self.class.faraday_adapter || Faraday.default_adapter
      @symbolize_keys = symbolize_keys || self.class.symbolize_keys || false
      @debug = debug || self.class.debug || false
      @test = test || self.class.test || false
      @logger = logger || self.class.logger || ::Logger.new(STDOUT)
    end

    def method_missing(method, *args)
      p = method.to_s.split('_').collect(&:capitalize).join
      p[0] = p[0].to_s.downcase
      @path_parts << p
      @path_parts << args if args.length > 0
      @path_parts.flatten!
      self
    end

    def respond_to_missing?(method_name, include_private = false)
      true
    end

    def send(*args)
      if args.length == 0
        method_missing(:send, args)
      else
        __send__(*args)
      end
    end

    def path
      @path_parts.join('/')
    end

    def create(params: nil, headers: nil, body: {})
      APIRequest.new(builder: self).post(params: params, headers: headers, body: body)
    ensure
      reset
    end

    def update(params: nil, headers: nil, body: {})
      APIRequest.new(builder: self).post(params: params, headers: headers, body: body)
    ensure
      reset
    end

    def retrieve(params: nil, headers: nil, body: {})
      APIRequest.new(builder: self).get(params: params, headers: headers, body: body)
    ensure
      reset
    end

    def delete(params: nil, headers: nil, body: {})
      APIRequest.new(builder: self).post(params: params, headers: headers, body: {})
    ensure
      reset
    end

    protected

    def reset
      @path_parts = []
    end

    class << self
      attr_accessor :access_token, :timeout, :open_timeout, :proxy, :faraday_adapter, :symbolize_keys,
                    :debug, :logger, :test

      def method_missing(sym, *args, &block)
        new(access_token: self.access_token,
            timeout: self.timeout, open_timeout: self.open_timeout, faraday_adapter: self.faraday_adapter,
            symbolize_keys: self.symbolize_keys, debug: self.debug, proxy: self.proxy,
            logger: self.logger,
            test: self.test).send(sym, *args, &block)
      end

      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
end
