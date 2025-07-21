#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv'
require_relative 'tools/supabase/zettel_service'

# Load environment variables
Dotenv.load

# Test embedding functionality
def test_embedding
  puts "Testing embedding functionality..."
  
  # Test the embedding generation directly
  service = ZettelService.new
  
  # Test text for embedding
  test_text = "This is a test note about artificial intelligence and machine learning concepts."
  
  puts "Generating embedding for: #{test_text}"
  
  # Use reflection to access the private method for testing
  embedding = service.send(:generate_embedding, test_text)
  
  if embedding
    puts "✅ Successfully generated embedding!"
    puts "Embedding dimensions: #{embedding.length}"
    puts "First 5 values: #{embedding.first(5)}"
  else
    puts "❌ Failed to generate embedding"
    puts "Make sure OPENAI_API_KEY is set in your environment"
  end
  
  puts "\nTesting note creation with embedding..."
  
  # Test creating a note with embedding
  result = service.create_note(
    title: "Test Note with Embedding",
    content: "This is a test note to verify that embeddings are generated and stored correctly.",
    note_type: "permanent",
    tags: ["test", "embedding"]
  )
  
  if result.is_a?(Hash) && result[:error]
    puts "❌ Failed to create note: #{result[:error]}"
  else
    puts "✅ Successfully created note with embedding!"
    puts "Note ID: #{result[:id]}"
    puts "Title: #{result[:title]}"
    puts "Has embedding: #{result[:embedding] ? 'Yes' : 'No'}"
  end
end

# Run the test
if __FILE__ == $0
  test_embedding
end 