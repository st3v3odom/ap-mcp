#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fast_mcp'
require 'cgi'
require_relative '../../lib/datadog/api' # Adjusted path to the new Datadog::Api

# Shared module for common Datadog log search functionality
module DatadogLogSearchBase
  private

  def initialize_datadog_api
    begin
      datadog_api = Datadog::Api.new
    rescue StandardError => e
      $logger&.error("#{self.class.name}: Failed to initialize Datadog::Api - #{e.class.name}: #{e.message}")
      return { error: "Failed to initialize Datadog API: #{e.message}" }
    end

    # Verify that API keys are effectively available via Datadog::Config
    unless Datadog::Config.api_key && Datadog::Config.application_key
      $logger&.warn("#{self.class.name}: DATADOG_API_KEY or DATADOG_APPLICATION_KEY environment variables not set or not accessible via Datadog::Config.")
      return { error: "Datadog API key (DATADOG_API_KEY) and Application key (DATADOG_APPLICATION_KEY) must be set in environment variables." }
    end

    datadog_api
  end

  def calculate_lookback_seconds(lookback)
    case lookback.to_s.downcase
    when 'hour'
      3600        # 1 hour in seconds
    when 'day'
      86400       # 1 day in seconds (24 * 60 * 60)
    when 'week'
      604800      # 1 week in seconds (7 * 24 * 60 * 60)
    else
      $logger&.warn("#{self.class.name}: Invalid lookback period '#{lookback}', defaulting to 'hour'")
      3600        # Default to 1 hour
    end
  end

  def search_logs(query, lookback = 'hour', page_limit = 25)
    datadog_api = initialize_datadog_api
    return datadog_api if datadog_api.is_a?(Hash) && datadog_api[:error] # Return error if initialization failed

    $logger&.info("#{self.class.name}: Initialized. Preparing to search logs with query: #{query}, lookback: #{lookback}")

    lookback_seconds = calculate_lookback_seconds(lookback)
    logs_api_instance = datadog_api.logs_api

    begin
      opts = {
        filter_query: query,
        filter_from: (Time.now - lookback_seconds).iso8601, # Search logs based on lookback period
        filter_to: Time.now.iso8601,           # Up to the current time
        sort: '-timestamp',                     # Sort by timestamp descending (newest first)
        page_limit: page_limit                  # Limit the number of results
      }

      $logger&.debug("#{self.class.name}: Calling list_logs_get with query: #{query}, lookback: #{lookback}, from: #{opts[:filter_from]}, to: #{opts[:filter_to]}, sort: #{opts[:sort]}, limit: #{opts[:page_limit]}")

      result = logs_api_instance.list_logs_get(opts)

      logs_data = result.data&.map do |log_item|
        attributes = log_item.attributes
        log_id = log_item.id

        # Create Datadog link using the correct 'event' parameter format
        datadog_link = "https://app.datadoghq.com/logs?query=#{CGI.escape(query)}&event=#{log_id}&fromUser=true&messageDisplay=inline&refresh_mode=sliding&storage=hot&stream_sort=desc&viz=stream"

        {
          id: log_id,
          message: attributes&.message,
          timestamp: attributes&.timestamp,
          tags: attributes&.tags,
          service: attributes&.service,
          host: attributes&.host,
          status: attributes&.status, # Common log status attribute
          datadog_link: datadog_link, # Direct link to this log in Datadog
          # Include all other non-nil top-level attributes from the log event's attributes
          details: attributes&.attributes&.reject { |_k, v| v.nil? }
        }
      end || [] # Default to an empty array if result.data is nil

      meta_data = result.meta&.to_hash # Include pagination metadata if available

      $logger&.info("#{self.class.name}: Found #{logs_data.count} logs.")
      { logs: logs_data, meta: meta_data }

    rescue DatadogAPIClient::APIError => e
      $logger&.error("#{self.class.name}: APIError - status code: #{e.code}, message: #{e.message}, response body: #{e.response_body}")
      # Sanitize or shorten error details if necessary before returning
      error_details = "Status Code: #{e.code}. Response: #{e.response_body || 'No response body.'}"
      error_details_truncated = error_details.length > 500 ? "#{error_details[0,500]}..." : error_details
      { error: "Datadog API error: #{e.message}", details: error_details_truncated }
    rescue StandardError => e
      $logger&.error("#{self.class.name}: StandardError - #{e.class.name}: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n  ")}")
      { error: "An unexpected error occurred: #{e.message}" }
    end
  end
end