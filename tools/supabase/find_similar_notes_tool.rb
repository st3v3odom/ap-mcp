#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'
require_relative 'zettel_service'

# Find notes similar to a Zettelkasten note
class FindSimilarNotesTool < FastMcp::Tool
  include SupabaseBase

  description "Finds notes similar to a specified Zettelkasten note based on shared tags and links."

  arguments do
    required(:note_id).filled(:string).description("The ID of the note to find similar notes for.")
    optional(:threshold).filled(:float).description("Similarity threshold (0.0 to 1.0). Only notes with similarity >= threshold are returned. Defaults to 0.3.")
    optional(:limit).filled(:integer).description("Maximum number of similar notes to return. Defaults to 5.")
  end

  def call(note_id:, threshold: 0.3, limit: 5)
    # Validate threshold
    if threshold < 0.0 || threshold > 1.0
      return { error: "Threshold must be between 0.0 and 1.0" }
    end

    # Initialize service
    service = ZettelService.new
    
    # Find similar notes
    result = service.find_similar_notes(note_id, threshold: threshold, limit: limit)

    # Return result
    if result.is_a?(Hash) && result[:error]
      { error: result[:error] }
    else
      {
        success: true,
        similar_notes: result,
        count: result.length,
        threshold: threshold,
        message: "Found #{result.length} notes similar to note ID '#{note_id}' (threshold: #{threshold})"
      }
    end
  rescue StandardError => e
    $logger&.error("#{self.class.name}: Error finding similar notes - #{e.class.name}: #{e.message}")
    { error: "Failed to find similar notes: #{e.message}" }
  end
end 