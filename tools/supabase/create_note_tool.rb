#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'
require_relative 'zettel_service'

# Create a new Zettelkasten note
class CreateNoteTool < FastMcp::Tool
  include SupabaseBase

  description "Creates a new Zettelkasten note with the specified title, content, and optional metadata."

  arguments do
    required(:title).filled(:string).description("The title of the note.")
    required(:content).filled(:string).description("The content/body of the note.")
    optional(:note_type).filled(:string).description("The type of note: 'permanent', 'fleeting', 'literature', 'structure', or 'hub'. Defaults to 'permanent'.")
    optional(:tags).filled(:string).description("Comma-separated list of tags for the note.")
  end

  def call(title:, content:, note_type: 'permanent', tags: nil)
    $logger&.info("#{self.class.name}: Starting create_note with title: #{title}")
    
    # Parse tags from comma-separated string
    parsed_tags = tags&.split(',')&.map(&:strip)&.reject(&:empty?)
    $logger&.debug("#{self.class.name}: Parsed tags: #{parsed_tags}")

    # Initialize service
    $logger&.info("#{self.class.name}: Initializing ZettelService")
    service = ZettelService.new
    $logger&.info("#{self.class.name}: ZettelService initialized successfully")
    
    # Create the note
    $logger&.info("#{self.class.name}: Calling service.create_note")
    result = service.create_note(
      title: title,
      content: content,
      note_type: note_type,
      tags: parsed_tags
    )
    $logger&.info("#{self.class.name}: Service.create_note completed, result: #{result.class}")

    # Return result
    if result.is_a?(Hash) && result[:error]
      { error: result[:error] }
    else
      {
        success: true,
        note: result,
        message: "Note '#{result[:title]}' created successfully with ID: #{result[:id]}"
      }
    end
  rescue StandardError => e
    $logger&.error("#{self.class.name}: Error creating note - #{e.class.name}: #{e.message}")
    { error: "Failed to create note: #{e.message}" }
  end
end 