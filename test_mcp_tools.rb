#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv'
require 'logger'

# Load environment variables
Dotenv.load

# Set up logging
$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG

# Load the tools
require_relative 'tools/supabase/create_note_tool'
require_relative 'tools/supabase/get_note_tool'
require_relative 'tools/supabase/search_notes_tool'
require_relative 'tools/supabase/get_all_tags_tool'

def test_create_note
  puts "\n=== Testing CreateNoteTool ==="
  tool = CreateNoteTool.new
  
  result = tool.call(
    title: "Test Note #{Time.now.to_i}",
    content: "This is a test note created at #{Time.now}",
    note_type: "permanent",
    tags: "test, mcp, ruby"
  )
  
  puts "Result: #{result}"
  result
end

def test_get_note(note_id)
  puts "\n=== Testing GetNoteTool ==="
  tool = GetNoteTool.new
  
  result = tool.call(note_id: note_id)
  puts "Result: #{result}"
  result
end

def test_search_notes
  puts "\n=== Testing SearchNotesTool ==="
  tool = SearchNotesTool.new
  
  result = tool.call(
    query: "test",
    limit: 5
  )
  puts "Result: #{result}"
  result
end

def test_get_all_tags
  puts "\n=== Testing GetAllTagsTool ==="
  tool = GetAllTagsTool.new
  
  result = tool.call
  puts "Result: #{result}"
  result
end

def test_full_workflow
  puts "\n=== Testing Full Workflow ==="
  
  # 1. Create a note
  create_result = test_create_note
  return unless create_result[:success]
  
  note_id = create_result[:note][:id]
  puts "Created note with ID: #{note_id}"
  
  # 2. Get the note back
  get_result = test_get_note(note_id)
  
  # 3. Search for notes
  search_result = test_search_notes
  
  # 4. Get all tags
  tags_result = test_get_all_tags
  
  puts "\n=== Workflow Summary ==="
  puts "Create: #{create_result[:success] ? '✅' : '❌'}"
  puts "Get: #{get_result[:success] ? '✅' : '❌'}"
  puts "Search: #{search_result[:success] ? '✅' : '❌'}"
  puts "Tags: #{tags_result[:success] ? '✅' : '❌'}"
end

def test_individual_tools
  puts "\n=== Testing Individual Tools ==="
  
  puts "\n1. Testing CreateNoteTool..."
  test_create_note
  
  puts "\n2. Testing GetAllTagsTool..."
  test_get_all_tags
  
  puts "\n3. Testing SearchNotesTool..."
  test_search_notes
end

# Main test execution
if ARGV.include?('--workflow')
  test_full_workflow
elsif ARGV.include?('--create')
  test_create_note
elsif ARGV.include?('--search')
  test_search_notes
elsif ARGV.include?('--tags')
  test_get_all_tags
elsif ARGV.include?('--get') && ARGV[1]
  test_get_note(ARGV[1])
else
  puts "MCP Tools Test Script"
  puts "===================="
  puts "Usage:"
  puts "  ruby test_mcp_tools.rb --workflow    # Test full workflow"
  puts "  ruby test_mcp_tools.rb --create      # Test create note"
  puts "  ruby test_mcp_tools.rb --search      # Test search notes"
  puts "  ruby test_mcp_tools.rb --tags        # Test get all tags"
  puts "  ruby test_mcp_tools.rb --get <id>    # Test get specific note"
  puts "  ruby test_mcp_tools.rb               # Test individual tools"
  
  test_individual_tools
end 