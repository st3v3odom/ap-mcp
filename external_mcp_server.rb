#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fast_mcp'
require 'logger'
require_relative 'lib/shortcut/api'
require_relative 'tools/shortcut/remote_get_story_tool'
require_relative 'lib/datadog/api'
require_relative 'tools/datadog/log_search_tool'

# Configure logging
$logger = Logger.new(STDERR)
$logger.level = Logger::INFO
$logger.info("External MCP Server started at #{Time.now}")

# Create MCP server for external/API-based tools only
server = FastMcp::Server.new(name: 'external-mcp', version: '1.0.0')

# Register only external API-based tools (remote-friendly versions)
server.register_tool(RemoteGetStoryTool)
server.register_tool(DatadogLogSearchTool)
server.register_tool(DatadogFailedCreditCardTool)

$logger.info("Starting External MCP server with stdio transport")
$logger.info("Available tools: #{server.tools.keys.join(', ')}")

# Start the server (only supports stdio transport)
server.start
