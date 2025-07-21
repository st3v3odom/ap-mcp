#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'
require_relative 'zettel_service'

# Search Zettelkasten notes using semantic similarity
class SearchNotesSemanticTool < FastMcp::Tool
  include SupabaseBase

  description "Searches for Zettelkasten notes using semantic similarity (vector search) based on embeddings."

  arguments do
    required(:query).filled(:string).description("Text query to search for semantically similar notes.")
    optional(:limit).filled(:integer).description("Maximum number of results to return. Defaults to 50.")
    optional(:threshold).filled(:float).description("Similarity threshold (0.0 to 1.0). Defaults to 0.7.")
  end

  def call(query:, limit: 50, threshold: 0.7)
    # Validate threshold
    if threshold < 0.0 || threshold > 1.0
      return { error: "Threshold must be between 0.0 and 1.0" }
    end

    # Initialize service
    service = ZettelService.new
    
    # Search for notes using semantic similarity
    result = service.search_notes_semantic(
      query: query,
      limit: limit,
      threshold: threshold
    )

    # Return result
    if result.is_a?(Hash) && result[:error]
      { error: result[:error] }
    else
      {
        success: true,
        notes: result,
        count: result.length,
        message: "Found #{result.length} semantically similar notes for query: '#{query}'"
      }
    end
  rescue StandardError => e
    $logger&.error("#{self.class.name}: Error performing semantic search - #{e.class.name}: #{e.message}")
    { error: "Failed to perform semantic search: #{e.message}" }
  end
end 