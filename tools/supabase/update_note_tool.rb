#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'
require_relative 'zettel_service'

# Update an existing Zettelkasten note
class UpdateNoteTool < FastMcp::Tool
  include SupabaseBase

  description "Updates an existing Zettelkasten note with new title, content, type, tags, or metadata."

  arguments do
    required(:note_id).filled(:string).description("The ID of the note to update.")
    optional(:title).filled(:string).description("The new title for the note.")
    optional(:content).filled(:string).description("The new content for the note.")
    optional(:note_type).filled(:string).description("The new type of note: 'permanent', 'fleeting', 'literature', 'structure', or 'hub'.")
    optional(:tags).filled(:string).description("Comma-separated list of new tags for the note (replaces existing tags).")
  end

  def call(note_id:, title: nil, content: nil, note_type: nil, tags: nil)
    # Parse tags from comma-separated string
    parsed_tags = tags&.split(',')&.map(&:strip)&.reject(&:empty?)

    # Initialize service
    service = ZettelService.new
    
    # Update the note
    result = service.update_note(
      note_id: note_id,
      title: title,
      content: content,
      note_type: note_type,
      tags: parsed_tags
    )

    # Return result
    if result.is_a?(Hash) && result[:error]
      { error: result[:error] }
    else
      {
        success: true,
        note: result,
        message: "Note '#{result[:title]}' updated successfully"
      }
    end
  rescue StandardError => e
    $logger&.error("#{self.class.name}: Error updating note - #{e.class.name}: #{e.message}")
    { error: "Failed to update note: #{e.message}" }
  end
end 