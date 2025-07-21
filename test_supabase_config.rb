#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv'
require_relative 'lib/supabase/config'

# Load environment variables
Dotenv.load

puts "=== Supabase Configuration Test ==="
puts "SUPABASE_URL: #{ENV['SUPABASE_URL'] ? 'SET' : 'NOT SET'}"
puts "SUPABASE_ANON_KEY: #{ENV['SUPABASE_ANON_KEY'] ? 'SET' : 'NOT SET'}"
puts "SUPABASE_SERVICE_ROLE_KEY: #{ENV['SUPABASE_SERVICE_ROLE_KEY'] ? 'SET' : 'NOT SET'}"
puts "SUPABASE_DEBUG: #{ENV['SUPABASE_DEBUG']}"

begin
  puts "\n=== Testing Config Module ==="
  puts "Config URL: #{Supabase::Config.url}"
  puts "Config Anon Key: #{Supabase::Config.anon_key ? 'SET' : 'NOT SET'}"
  
  puts "\n=== Testing Config Validation ==="
  Supabase::Config.validate_config!
  puts "✅ Configuration validation passed!"
  
rescue => e
  puts "❌ Configuration validation failed: #{e.message}"
end

begin
  puts "\n=== Testing API Initialization ==="
  require_relative 'lib/supabase/api'
  api = Supabase::Api.new
  puts "✅ API initialization successful!"
  
  puts "\n=== Testing API Connection ==="
  # Try a simple GET request to test connection
  response = api.get('/')
  puts "✅ API connection test successful!"
  
rescue => e
  puts "❌ API test failed: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
end 