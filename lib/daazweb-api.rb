require 'faraday'
require 'daazweb-api/version'
require 'daazweb-api/daazweb_api_error'
require 'daazweb-api/request'
require 'daazweb-api/api_request'
require 'daazweb-api/response'

module DaazwebApi

  API_ENDPOINT = "https://daazweb.space/api/"

  class << self
    def setup
      yield self
    end

    def register(name, value, type = nil)
      cattr_accessor "#{name}_setting".to_sym

      add_reader(name)
      add_writer(name, type)
      send "#{name}=", value
    end

    def add_reader(name)
      define_singleton_method(name) do |*args|
        send("#{name}_setting").value(*args)
      end
    end

    def add_writer(name, type)
      define_singleton_method("#{name}=") do |value|
        send("#{name}_setting=", DynamicSetting.build(value, type))
      end
    end
  end

  class DynamicSetting
    def self.build(setting, type)
      (type ? klass(type) : self).new(setting)
    end

    def self.klass(type)
      klass = "#{type.to_s.camelcase}Setting"
      raise ArgumentError, "Unknown type: #{type}" unless DaazwebApi.const_defined?(klass)
      DaazwebApi.const_get(klass)
    end

    def initialize(setting)
      @setting = setting
    end

    def value(*_args)
      @setting
    end
  end
end

enable :inline_templates