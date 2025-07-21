#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv'
require 'logger'

# Load environment variables
Dotenv.load

# Set up logging
$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO

# Load all Zettelkasten tools
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

class ZettelkastenTestSuite
  def initialize
    @test_notes = []
    @test_links = []
    @results = {}
  end

  def run_all_tests
    puts "🧪 Running Comprehensive Zettelkasten Test Suite"
    puts "=" * 60
    
    test_create_note
    test_get_note
    test_update_note
    test_search_notes
    # test_search_notes_semantic  # Commented out - requires OpenAI API
    test_create_link
    test_get_linked_notes
    test_find_similar_notes
    test_get_all_tags
    test_delete_note
    
    print_summary
  end

  def test_create_note
    puts "\n📝 Testing CreateNoteTool..."
    
    tool = CreateNoteTool.new
    
    # Test 1: Basic note creation
    result1 = tool.call(
      title: "Test Note #{Time.now.to_i}",
      content: "This is a test note for comprehensive testing.",
      note_type: "permanent",
      tags: "test, comprehensive, ruby"
    )
    
    if result1[:success]
      @test_notes << result1[:note][:id]
      puts "✅ Basic note creation: SUCCESS"
      puts "   Note ID: #{result1[:note][:id]}"
      puts "   Has embedding: #{result1[:note][:embedding] ? 'Yes' : 'No'}"
    else
      puts "❌ Basic note creation: FAILED - #{result1[:error]}"
    end
    
    # Test 2: Note with different types
    result2 = tool.call(
      title: "Fleeting Note #{Time.now.to_i}",
      content: "This is a fleeting note for testing different note types.",
      note_type: "fleeting",
      tags: "fleeting, test"
    )
    
    if result2[:success]
      @test_notes << result2[:note][:id]
      puts "✅ Fleeting note creation: SUCCESS"
    else
      puts "❌ Fleeting note creation: FAILED - #{result2[:error]}"
    end
    
    @results[:create_note] = { success: result1[:success] && result2[:success] }
  end

  def test_get_note
    puts "\n🔍 Testing GetNoteTool..."
    
    return if @test_notes.empty?
    
    tool = GetNoteTool.new
    
    # Test by ID
    result1 = tool.call(note_id: @test_notes.first)
    if result1[:success]
      puts "✅ Get note by ID: SUCCESS"
      puts "   Title: #{result1[:note][:title]}"
      puts "   Has embedding: #{result1[:note][:embedding] ? 'Yes' : 'No'}"
    else
      puts "❌ Get note by ID: FAILED - #{result1[:error]}"
    end
    
    # Test by title
    result2 = tool.call(title: result1[:note][:title]) if result1[:success]
    if result2 && result2[:success]
      puts "✅ Get note by title: SUCCESS"
    else
      puts "❌ Get note by title: FAILED - #{result2&.dig(:error)}"
    end
    
    @results[:get_note] = { success: result1[:success] && (result2&.dig(:success) || false) }
  end

  def test_update_note
    puts "\n✏️  Testing UpdateNoteTool..."
    
    return if @test_notes.empty?
    
    tool = UpdateNoteTool.new
    
    result = tool.call(
      note_id: @test_notes.first,
      title: "Updated Test Note #{Time.now.to_i}",
      content: "This note has been updated for testing purposes.",
      tags: "updated, test, comprehensive"
    )
    
    if result[:success]
      puts "✅ Update note: SUCCESS"
      puts "   New title: #{result[:note][:title]}"
      puts "   Has embedding: #{result[:note][:embedding] ? 'Yes' : 'No'}"
    else
      puts "❌ Update note: FAILED - #{result[:error]}"
    end
    
    @results[:update_note] = { success: result[:success] }
  end

  def test_search_notes
    puts "\n🔎 Testing SearchNotesTool..."
    
    tool = SearchNotesTool.new
    
    # Test basic search
    result1 = tool.call(
      query: "test",
      limit: 5
    )
    
    if result1[:success]
      puts "✅ Basic search: SUCCESS"
      puts "   Found #{result1[:count]} notes"
    else
      puts "❌ Basic search: FAILED - #{result1[:error]}"
    end
    
    # Test search by type
    result2 = tool.call(
      note_type: "permanent",
      limit: 5
    )
    
    if result2[:success]
      puts "✅ Search by type: SUCCESS"
      puts "   Found #{result2[:count]} permanent notes"
    else
      puts "❌ Search by type: FAILED - #{result2[:error]}"
    end
    
    @results[:search_notes] = { success: result1[:success] && result2[:success] }
  end

  # def test_search_notes_semantic
  #   puts "\n🧠 Testing SearchNotesSemanticTool..."
  #   
  #   tool = SearchNotesSemanticTool.new
  #   
  #   result = tool.call(
  #     query: "testing and comprehensive evaluation",
  #     limit: 5,
  #     threshold: 0.5
  #   )
  #   
  #   if result[:success]
  #     puts "✅ Semantic search: SUCCESS"
  #     puts "   Found #{result[:count]} semantically similar notes"
  #   else
  #     puts "❌ Semantic search: FAILED - #{result[:error]}"
  #     puts "   Note: This might fail if OpenAI API key is not set or embeddings are not configured"
  #   end
  #   
  #   @results[:search_notes_semantic] = { success: result[:success] }
  # end

  def test_create_link
    puts "\n🔗 Testing CreateLinkTool..."
    
    return if @test_notes.length < 2
    
    tool = CreateLinkTool.new
    
    result = tool.call(
      source_id: @test_notes[0],
      target_id: @test_notes[1],
      link_type: "reference",
      description: "Test link for comprehensive testing",
      bidirectional: true
    )
    
    if result[:success]
      puts "✅ Create link: SUCCESS"
      puts "   Link type: reference"
      puts "   Bidirectional: true"
      @test_links << { source: @test_notes[0], target: @test_notes[1] }
    else
      puts "❌ Create link: FAILED - #{result[:error]}"
    end
    
    @results[:create_link] = { success: result[:success] }
  end

  def test_get_linked_notes
    puts "\n🔗 Testing GetLinkedNotesTool..."
    
    return if @test_notes.empty?
    
    tool = GetLinkedNotesTool.new
    
    # Test outgoing links
    result1 = tool.call(
      note_id: @test_notes.first,
      direction: "outgoing"
    )
    
    if result1[:success]
      puts "✅ Get outgoing links: SUCCESS"
      puts "   Found #{result1[:notes]&.length || 0} outgoing links"
    else
      puts "❌ Get outgoing links: FAILED - #{result1[:error]}"
    end
    
    # Test incoming links
    result2 = tool.call(
      note_id: @test_notes.first,
      direction: "incoming"
    )
    
    if result2[:success]
      puts "✅ Get incoming links: SUCCESS"
      puts "   Found #{result2[:notes]&.length || 0} incoming links"
    else
      puts "❌ Get incoming links: FAILED - #{result2[:error]}"
    end
    
    @results[:get_linked_notes] = { success: result1[:success] && result2[:success] }
  end

  def test_find_similar_notes
    puts "\n🎯 Testing FindSimilarNotesTool..."
    
    return if @test_notes.empty?
    
    tool = FindSimilarNotesTool.new
    
    result = tool.call(
      note_id: @test_notes.first,
      threshold: 0.3,
      limit: 5
    )
    
    if result[:success]
      puts "✅ Find similar notes: SUCCESS"
      puts "   Found #{result[:similar_notes]&.length || 0} similar notes"
    else
      puts "❌ Find similar notes: FAILED - #{result[:error]}"
    end
    
    @results[:find_similar_notes] = { success: result[:success] }
  end

  def test_get_all_tags
    puts "\n🏷️  Testing GetAllTagsTool..."
    
    tool = GetAllTagsTool.new
    
    result = tool.call
    
    if result[:success]
      puts "✅ Get all tags: SUCCESS"
      puts "   Found #{result[:tags].length} tags"
      if result[:tags].any?
        puts "   Sample tags: #{result[:tags].first(3).map { |t| t[:name] }.join(', ')}"
      end
    else
      puts "❌ Get all tags: FAILED - #{result[:error]}"
    end
    
    @results[:get_all_tags] = { success: result[:success] }
  end

  def test_delete_note
    puts "\n🗑️  Testing DeleteNoteTool..."
    
    return if @test_notes.empty?
    
    tool = DeleteNoteTool.new
    
    # Delete the last test note
    note_to_delete = @test_notes.last
    result = tool.call(note_id: note_to_delete)
    
    if result[:success]
      puts "✅ Delete note: SUCCESS"
      puts "   Deleted note ID: #{note_to_delete}"
      @test_notes.pop
    else
      puts "❌ Delete note: FAILED - #{result[:error]}"
    end
    
    @results[:delete_note] = { success: result[:success] }
  end

  def print_summary
    puts "\n" + "=" * 60
    puts "📊 TEST SUMMARY"
    puts "=" * 60
    
    total_tests = @results.length
    passed_tests = @results.values.count { |r| r[:success] }
    failed_tests = total_tests - passed_tests
    
    @results.each do |test_name, result|
      status = result[:success] ? "✅" : "❌"
      puts "#{status} #{test_name.to_s.gsub('_', ' ').capitalize}"
    end
    
    puts "\n📈 OVERALL RESULTS:"
    puts "   Total tests: #{total_tests}"
    puts "   Passed: #{passed_tests}"
    puts "   Failed: #{failed_tests}"
    puts "   Success rate: #{(passed_tests.to_f / total_tests * 100).round(1)}%"
    
    if failed_tests > 0
      puts "\n⚠️  NOTES:"
      puts "   - Some tests may fail if Supabase is not configured"
      puts "   - Semantic search requires OpenAI API key"
      puts "   - Embedding tests require proper database setup"
    end
    
    puts "\n🧹 Cleanup:"
    puts "   Test notes created: #{@test_notes.length}"
    puts "   Test links created: #{@test_links.length}"
    puts "   Consider cleaning up test data manually if needed"
  end
end

# Main execution
if __FILE__ == $0
  test_suite = ZettelkastenTestSuite.new
  test_suite.run_all_tests
end 