#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fast_mcp'
require 'logger'
require_relative 'lib/shortcut/api'
require_relative 'tools/project/project_helper'
require_relative 'tools/project/switch_project_tool'
require_relative 'tools/project/current_project_tool'
require_relative 'tools/search/dev_log_search_tool'
require_relative 'tools/shortcut/get_story_tool'
require_relative 'tools/git/get_branch_tool'
require_relative 'lib/datadog/api'
require_relative 'tools/datadog/log_search_tool'
require_relative 'tools/local_dev/local_health_tool'

# Configure logging
$logger = Logger.new(File.expand_path('mcp_server.log', __dir__), 'daily')
$logger.level = Logger::DEBUG
$logger.info("Fast-MCP Server started at #{Time.now}")

# Create MCP server
server = FastMcp::Server.new(name: 'project-mcp', version: '1.0.0')

# Register tools with the server
server.register_tool(SwitchProjectTool)
server.register_tool(CurrentProjectTool)
server.register_tool(DevLogSearchTool)
server.register_tool(GetStoryTool)
server.register_tool(GetBranchTool)
server.register_tool(DatadogLogSearchTool)
server.register_tool(LocalHealthTool)

# Start the server
$logger.info("Starting Fast-MCP server with tools: #{server.tools.keys.join(', ')}")
server.start