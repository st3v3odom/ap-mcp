#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'

# General Datadog log search tool
class DatadogLogSearchTool < FastMcp::Tool
  include DatadogLogSearchBase

  description "Searches Datadog logs using a specified query. The user may also refer Datadog as dd or dd logs"

  arguments do
    required(:query).filled(:string).description("The search query to use for filtering Datadog logs.")
    optional(:lookback).filled(:string).description("The time period to search back: 'hour', 'day', or 'week'. Defaults to 'hour'.")
  end

  def call(query:, lookback: 'hour')
    search_logs(query, lookback)
  end
end