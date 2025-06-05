#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/datadog/api'
require_relative '../tools/datadog/log_search_tool'

# Extract Datadog links for NetSuite logs
puts "=== Extracting Datadog Links for NetSuite Logs ==="

tool = DatadogLogSearchTool.new
result = tool.call(query: "netsuite")

if result[:data] && result[:data][:logs]
  puts "\n=== NetSuite-Related Datadog Log Links ==="
  puts "Found #{result[:data][:logs].length} logs\n"

  result[:data][:logs].each_with_index do |log, index|
    log_id = log[:id]
    timestamp = log[:timestamp]
    service = log[:service]

    # Create Datadog link using the correct 'event' parameter format
    datadog_link = "https://app.datadoghq.com/logs?query=netsuite&event=#{log_id}&fromUser=true&messageDisplay=inline&refresh_mode=sliding&storage=hot&stream_sort=desc&viz=stream"

    puts "#{index + 1}. **#{service}** (#{timestamp})"
    puts "   Log ID: #{log_id}"
    puts "   Link: #{datadog_link}"
    puts "   Message preview: #{log[:message][0..100]}..."
    puts
  end
else
  puts "No logs found or error occurred"
end