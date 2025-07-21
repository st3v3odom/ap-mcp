#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fast_mcp'
require 'logger'
require 'dotenv'

# Load environment variables from .env file
Dotenv.load
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
require_relative 'lib/supabase/api'
require_relative 'tools/supabase/create_note_tool'
require_relative 'tools/supabase/get_note_tool'
require_relative 'tools/supabase/update_note_tool'
require_relative 'tools/supabase/delete_note_tool'
require_relative 'tools/supabase/search_notes_tool'
# require_relative 'tools/supabase/search_notes_semantic_tool'  # Commented out - requires OpenAI API
require_relative 'tools/supabase/create_link_tool'
require_relative 'tools/supabase/get_linked_notes_tool'
require_relative 'tools/supabase/find_similar_notes_tool'
require_relative 'tools/supabase/get_all_tags_tool'

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
server.register_tool(LocalHealthTool)

# Register Supabase Zettelkasten tools
server.register_tool(CreateNoteTool)
server.register_tool(GetNoteTool)
server.register_tool(UpdateNoteTool)
server.register_tool(DeleteNoteTool)
server.register_tool(SearchNotesTool)
# server.register_tool(SearchNotesSemanticTool)  # Commented out - requires OpenAI API
server.register_tool(CreateLinkTool)
server.register_tool(GetLinkedNotesTool)
server.register_tool(FindSimilarNotesTool)
server.register_tool(GetAllTagsTool)

# Determine transport method from command line args or environment
transport = ARGV.include?('--stdio') ? :stdio : (ENV['MCP_TRANSPORT']&.to_sym || :sse)
port = ENV['PORT'] || 8000

# Start the server
$logger.info("Starting Fast-MCP server with transport: #{transport}")
$logger.info("Available tools: #{server.tools.keys.join(', ')}")

# Note: fast-mcp gem only supports stdio transport via the start method
# For HTTP/SSE transport, we would need to use Rack middleware
if transport == :stdio
  server.start
else
  $logger.error("This version of fast-mcp only supports stdio transport via server.start")
  $logger.error("For HTTP/SSE transport, use Rack middleware integration")
  exit 1
end