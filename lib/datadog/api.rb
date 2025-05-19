# frozen_string_literal: true

require 'datadog_api_client'
require_relative 'config'

module Datadog
  class Api
    def initialize
      DatadogAPIClient.configure do |config|
        config.api_key = Datadog::Config.api_key
        config.application_key = Datadog::Config.application_key
        config.server_variables[:site] = Datadog::Config.site if Datadog::Config.site
        config.debugging = Datadog::Config.debugging
      end
    end

    # Example: Expose the LogsAPI directly or add wrapper methods
    def logs_api
      @logs_api ||= DatadogAPIClient::V2::LogsAPI.new
    end

    # Add other Datadog API namespaces as needed, e.g.:
    # def metrics_api
    #   @metrics_api ||= DatadogAPIClient::V2::MetricsAPI.new
    # end
  end
end