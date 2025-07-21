#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'
require_relative 'zettel_service'

# Get a Zettelkasten note by ID or title
class GetNoteTool < FastMcp::Tool
  include SupabaseBase

  description "Retrieves a Zettelkasten note by ID or title."

  arguments do
    optional(:note_id).filled(:string).description("The ID of the note to retrieve.")
    optional(:title).filled(:string).description("The title of the note to retrieve (alternative to note_id).")
  end

  def call(note_id: nil, title: nil)
    # Validate that at least one identifier is provided
    if note_id.nil? && title.nil?
      return { error: "Either note_id or title must be provided" }
    end

    # Initialize service
    service = ZettelService.new
    
    # Get the note
    result = if note_id
      service.get_note(note_id)
    else
      service.get_note_by_title(title)
    end

    # Return result
    if result.is_a?(Hash) && result[:error]
      { error: result[:error] }
    else
      {
        success: true,
        note: result,
        message: "Note '#{result[:title]}' retrieved successfully"
      }
    end
  rescue StandardError => e
    $logger&.error("#{self.class.name}: Error retrieving note - #{e.class.name}: #{e.message}")
    { error: "Failed to retrieve note: #{e.message}" }
  end
end 