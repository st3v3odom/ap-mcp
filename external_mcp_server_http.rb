#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'fast_mcp'
require 'logger'
require_relative 'lib/shortcut/api'
require_relative 'tools/shortcut/remote_get_story_tool'
require_relative 'lib/datadog/api'
require_relative 'tools/datadog/log_search_tool'

# Configure logging
$logger = Logger.new(STDERR)
$logger.level = Logger::INFO
$logger.info("External MCP HTTP Server started at #{Time.now}")

# Configure Sinatra
set :port, ENV['PORT'] || 8000
set :bind, '0.0.0.0'

# Use FastMcp middleware with Sinatra
use FastMcp::RackMiddleware.new(name: 'external-mcp', version: '1.0.0') do |server|
  # Register only external API-based tools (remote-friendly versions)
  server.register_tool(RemoteGetStoryTool)
  server.register_tool(DatadogLogSearchTool)
  server.register_tool(DatadogFailedCreditCardTool)

  $logger.info("Registered tools: #{server.tools.keys.join(', ')}")
end

# Simple health check endpoint
get '/' do
  content_type :json
  {
    status: 'ok',
    server: 'external-mcp',
    version: '1.0.0',
    sse_endpoint: '/sse',
    tools: ['RemoteGetStoryTool', 'DatadogLogSearchTool', 'DatadogFailedCreditCardTool']
  }.to_json
end

# Health check for Fly.io
get '/health' do
  'OK'
end

$logger.info("Server starting on port #{settings.port}")
$logger.info("SSE endpoint will be available at /sse")