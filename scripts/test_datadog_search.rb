#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/datadog/api'
require_relative '../tools/datadog/log_search_tool'

# Test the DatadogLogSearchTool directly
puts "=== Testing DatadogLogSearchTool with 'zuora' query ==="

tool = DatadogLogSearchTool.new
result = tool.call(query: "zuora")

puts "Result:"
puts result.inspect