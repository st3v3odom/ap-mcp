#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv'
require 'logger'

# Load environment variables
Dotenv.load

# Set up logging
$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO

# Load the tools
require_relative 'tools/supabase/create_note_tool'
require_relative 'tools/supabase/get_note_tool'
require_relative 'tools/supabase/search_notes_tool'
require_relative 'tools/supabase/get_all_tags_tool'

def show_menu
  puts "\n=== MCP Tools Interactive Test ==="
  puts "1. Create a note"
  puts "2. Get a note by ID"
  puts "3. Search notes"
  puts "4. Get all tags"
  puts "5. Test full workflow"
  puts "6. Exit"
  print "\nChoose an option (1-6): "
end

def create_note_interactive
  puts "\n=== Create Note ==="
  print "Title: "
  title = gets.chomp
  return if title.empty?
  
  print "Content: "
  content = gets.chomp
  return if content.empty?
  
  print "Note type (permanent/fleeting/literature/structure/hub) [permanent]: "
  note_type = gets.chomp
  note_type = 'permanent' if note_type.empty?
  
  print "Tags (comma-separated): "
  tags = gets.chomp
  
  tool = CreateNoteTool.new
  result = tool.call(
    title: title,
    content: content,
    note_type: note_type,
    tags: tags
  )
  
  puts "\nResult: #{result}"
  result
end

def get_note_interactive
  puts "\n=== Get Note ==="
  print "Note ID: "
  note_id = gets.chomp
  return if note_id.empty?
  
  tool = GetNoteTool.new
  result = tool.call(note_id: note_id)
  
  puts "\nResult: #{result}"
  result
end

def search_notes_interactive
  puts "\n=== Search Notes ==="
  print "Query: "
  query = gets.chomp
  
  print "Note type filter (optional): "
  note_type = gets.chomp
  note_type = nil if note_type.empty?
  
  print "Tags filter (comma-separated, optional): "
  tags = gets.chomp
  tags = nil if tags.empty?
  
  print "Limit [50]: "
  limit_str = gets.chomp
  limit = limit_str.empty? ? 50 : limit_str.to_i
  
  tool = SearchNotesTool.new
  result = tool.call(
    query: query,
    note_type: note_type,
    tags: tags,
    limit: limit
  )
  
  puts "\nResult: #{result}"
  result
end

def get_all_tags_interactive
  puts "\n=== Get All Tags ==="
  
  tool = GetAllTagsTool.new
  result = tool.call
  
  puts "\nResult: #{result}"
  result
end

def test_workflow_interactive
  puts "\n=== Testing Full Workflow ==="
  
  # Create a note
  puts "Step 1: Creating a test note..."
  create_result = create_note_interactive
  return unless create_result && create_result[:success]
  
  note_id = create_result[:note][:id]
  puts "Created note with ID: #{note_id}"
  
  # Get the note
  puts "\nStep 2: Retrieving the note..."
  get_result = get_note_interactive
  puts "Get result: #{get_result[:success] ? '✅' : '❌'}"
  
  # Search notes
  puts "\nStep 3: Searching for notes..."
  search_result = search_notes_interactive
  puts "Search result: #{search_result[:success] ? '✅' : '❌'}"
  
  # Get tags
  puts "\nStep 4: Getting all tags..."
  tags_result = get_all_tags_interactive
  puts "Tags result: #{tags_result[:success] ? '✅' : '❌'}"
  
  puts "\n=== Workflow Complete ==="
end

# Main interactive loop
loop do
  show_menu
  choice = gets.chomp
  
  case choice
  when '1'
    create_note_interactive
  when '2'
    get_note_interactive
  when '3'
    search_notes_interactive
  when '4'
    get_all_tags_interactive
  when '5'
    test_workflow_interactive
  when '6'
    puts "Goodbye!"
    break
  else
    puts "Invalid choice. Please try again."
  end
end 