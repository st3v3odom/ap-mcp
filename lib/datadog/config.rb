# frozen_string_literal: true

module Datadog
  module Config
    module_function

    def api_key
      ENV['DATADOG_KEY_ID']
    end

    def application_key
      ENV['DATADOG_APPLICATION_KEY']
    end

    def site
      "datadoghq.com" # "ENV['DD_SITE'] # e.g., 'datadoghq.com', 'datadoghq.eu', 'us3.datadoghq.com'
    end

    def debugging
      true
    end
  end
end