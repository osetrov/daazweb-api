# frozen_string_literal: true

module DaazwebApi
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def generate_install
      copy_file 'daazweb-api.yml', 'config/daazweb-api.yml'
      copy_file 'daazweb-api.rb', 'config/initializers/daazweb-api.rb'
    end
  end
end

