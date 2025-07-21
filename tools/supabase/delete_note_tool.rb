#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'
require_relative 'zettel_service'

# Delete a Zettelkasten note
class DeleteNoteTool < FastMcp::Tool
  include SupabaseBase

  description "Deletes a Zettelkasten note by ID."

  arguments do
    required(:note_id).filled(:string).description("The ID of the note to delete.")
  end

  def call(note_id:)
    # Initialize service
    service = ZettelService.new
    
    # Delete the note
    result = service.delete_note(note_id)

    # Return result
    if result.is_a?(Hash) && result[:error]
      { error: result[:error] }
    else
      {
        success: true,
        message: "Note with ID '#{note_id}' deleted successfully"
      }
    end
  rescue StandardError => e
    $logger&.error("#{self.class.name}: Error deleting note - #{e.class.name}: #{e.message}")
    { error: "Failed to delete note: #{e.message}" }
  end
end 