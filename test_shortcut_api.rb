#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple script to test Shortcut API directly without MCP
require_relative 'lib/shortcut/api'

# Set an API key directly if not available from Config
Shortcut::Config.module_eval do
  def self.api_key
    ENV['SHORTCUT_API_TOKEN'] || "***REMOVED***"
  end
end

# Story ID to fetch
story_id = 85724

puts "Testing direct Shortcut API access..."
puts "Configuration:"
puts "  API Key: #{Shortcut::Config.api_key[0..5]}..." if Shortcut::Config.api_key
puts "  Endpoint: #{Shortcut::Config.endpoint}"
puts ""

# Create API client
api = Shortcut::Api.new
puts "Fetching story ##{story_id}..."

begin
  story = api.get_story(story_id)
  puts "Success! Received story data:"
  puts "  Title: #{story['name']}"
  puts "  Type: #{story['story_type']}"
  puts "  Created: #{story['created_at']}"
  puts "  State: #{story['completed'] ? 'Completed' : 'In Progress'}"
rescue => e
  puts "Error fetching story: #{e.class} - #{e.message}"
  puts e.backtrace[0..5] if e.backtrace
end