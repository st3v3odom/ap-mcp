# frozen_string_literal: true

module Supabase
  module Config
    module_function

    def url
      ENV['SUPABASE_URL']
    end

    def anon_key
      ENV['SUPABASE_ANON_KEY']
    end

    def service_role_key
      ENV['SUPABASE_SERVICE_ROLE_KEY']
    end

    def database_url
      ENV['SUPABASE_DATABASE_URL']
    end

    def debugging
      ENV['SUPABASE_DEBUG'] == 'true'
    end

    def validate_config!
      missing_vars = []
      missing_vars << 'SUPABASE_URL' unless url
      missing_vars << 'SUPABASE_ANON_KEY' unless anon_key
      
      if missing_vars.any?
        raise "Missing required Supabase environment variables: #{missing_vars.join(', ')}"
      end
    end
  end
end 