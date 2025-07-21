#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'
require_relative 'zettel_service'

# Search Zettelkasten notes
class SearchNotesTool < FastMcp::Tool
  include SupabaseBase

  description "Searches for Zettelkasten notes based on query, type, tags, or other criteria."

  arguments do
    optional(:query).filled(:string).description("Text to search for in note titles and content.")
    optional(:note_type).filled(:string).description("Filter by note type: 'permanent', 'fleeting', 'literature', 'structure', or 'hub'.")
    optional(:tags).filled(:string).description("Comma-separated list of tags to filter by.")
    optional(:limit).filled(:integer).description("Maximum number of results to return. Defaults to 50.")
  end

  def call(query: nil, note_type: nil, tags: nil, limit: 50)
    # Parse tags from comma-separated string
    parsed_tags = tags&.split(',')&.map(&:strip)&.reject(&:empty?)

    # Initialize service
    service = ZettelService.new
    
    # Search for notes
    result = service.search_notes(
      query: query,
      note_type: note_type,
      tags: parsed_tags,
      limit: limit
    )

    # Return result
    if result.is_a?(Hash) && result[:error]
      { error: result[:error] }
    else
      {
        success: true,
        notes: result,
        count: result.length,
        message: "Found #{result.length} notes matching the search criteria"
      }
    end
  rescue StandardError => e
    $logger&.error("#{self.class.name}: Error searching notes - #{e.class.name}: #{e.message}")
    { error: "Failed to search notes: #{e.message}" }
  end
end 