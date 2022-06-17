require 'daazweb-api'

DaazwebApi.setup do |config|
  if File.exist?('config/daazweb-api.yml')
    processed = YAML.load_file('config/daazweb-api.yml')[Rails.env]

    processed.each do |k, v|
      config::register k.underscore.to_sym, v
    end

    config::Request.timeout = 60
    config::Request.open_timeout = 60
    config::Request.symbolize_keys = true
    config::Request.debug = false
  end
end