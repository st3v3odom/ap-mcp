#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fast_mcp'
require_relative '../../lib/datadog/api' # Adjusted path to the new Datadog::Api

# Define the DatadogLogSearchTool
class DatadogLogSearchTool < FastMcp::Tool
  description "Searches Datadog logs using a specified query. Requires DD_API_KEY and DD_APP_KEY environment variables."

  # The `call` method will receive the query as a keyword argument, e.g., call(query: "my search")
  # This convention is based on how other tools with parameters are invoked in the MCP system.
  def call(query:)
    # Initialize Datadog API. Configuration is handled within Datadog::Api and Datadog::Config
    begin
      datadog_api = Datadog::Api.new
    rescue StandardError => e
      $logger&.error("DatadogLogSearchTool: Failed to initialize Datadog::Api - #{e.class.name}: #{e.message}")
      return { error: "Failed to initialize Datadog API: #{e.message}" }
    end

    # Verify that API keys are effectively available via Datadog::Config
    # This check is now more about confirming that the environment variables were picked up by the config module.
    unless Datadog::Config.api_key && Datadog::Config.application_key
      $logger&.warn("DatadogLogSearchTool: DD_API_KEY or DD_APP_KEY environment variables not set or not accessible via Datadog::Config.")
      return { error: "Datadog API key (DD_API_KEY) and Application key (DD_APP_KEY) must be set in environment variables." }
    end

    $logger&.info("DatadogLogSearchTool: Initialized. Preparing to search logs with query: #{query}")

    # Get the logs API instance from our Datadog::Api wrapper
    logs_api_instance = datadog_api.logs_api

    begin
      opts = {
        filter_query: query,
        filter_from: (Time.now - 3600).iso8601, # Search logs from the last 1 hour
        filter_to: Time.now.iso8601,           # Up to the current time
        sort: '-timestamp',                     # Sort by timestamp descending (newest first)
        page_limit: 25                          # Limit the number of results
      }

      $logger&.debug("DatadogLogSearchTool: Calling list_logs_get with query: #{query}, from: #{opts[:filter_from]}, to: #{opts[:filter_to]}, sort: #{opts[:sort]}, limit: #{opts[:page_limit]}")

      result = logs_api_instance.list_logs_get(opts)

      logs_data = result.data&.map do |log_item|
        attributes = log_item.attributes
        {
          id: log_item.id,
          message: attributes&.message,
          timestamp: attributes&.timestamp,
          tags: attributes&.tags,
          service: attributes&.service,
          host: attributes&.host,
          status: attributes&.status, # Common log status attribute
          # Include all other non-nil top-level attributes from the log event's attributes
          details: attributes&.attributes&.reject { |_k, v| v.nil? }
        }
      end || [] # Default to an empty array if result.data is nil

      meta_data = result.meta&.to_hash # Include pagination metadata if available

      $logger&.info("DatadogLogSearchTool: Found #{logs_data.count} logs.")
      { logs: logs_data, meta: meta_data }

    rescue DatadogAPIClient::APIError => e
      $logger&.error("DatadogLogSearchTool: APIError - status code: #{e.code}, message: #{e.message}, response body: #{e.response_body}")
      # Sanitize or shorten error details if necessary before returning
      error_details = "Status Code: #{e.code}. Response: #{e.response_body || 'No response body.'}"
      error_details_truncated = error_details.length > 500 ? "#{error_details[0,500]}..." : error_details
      { error: "Datadog API error: #{e.message}", details: error_details_truncated }
    rescue StandardError => e
      $logger&.error("DatadogLogSearchTool: StandardError - #{e.class.name}: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n  ")}")
      { error: "An unexpected error occurred: #{e.message}" }
    end
  end
end
