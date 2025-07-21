#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'
require_relative 'zettel_service'

# Get notes linked to/from a Zettelkasten note
class GetLinkedNotesTool < FastMcp::Tool
  include SupabaseBase

  description "Retrieves notes that are linked to or from a specified Zettelkasten note."

  arguments do
    required(:note_id).filled(:string).description("The ID of the note to find linked notes for.")
    optional(:direction).filled(:string).description("Direction of links to retrieve: 'outgoing' (notes this note links to), 'incoming' (notes that link to this note), or 'both'. Defaults to 'outgoing'.")
  end

  def call(note_id:, direction: 'outgoing')
    # Initialize service
    service = ZettelService.new
    
    # Get linked notes
    result = service.get_linked_notes(note_id, direction: direction)

    # Return result
    if result.is_a?(Hash) && result[:error]
      { error: result[:error] }
    else
      {
        success: true,
        linked_notes: result,
        count: result.length,
        direction: direction,
        message: "Found #{result.length} #{direction} linked notes for note ID '#{note_id}'"
      }
    end
  rescue StandardError => e
    $logger&.error("#{self.class.name}: Error getting linked notes - #{e.class.name}: #{e.message}")
    { error: "Failed to get linked notes: #{e.message}" }
  end
end 