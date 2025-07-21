#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'
require_relative 'zettel_service'

# Create a link between Zettelkasten notes
class CreateLinkTool < FastMcp::Tool
  include SupabaseBase

  description "Creates a link between two Zettelkasten notes with optional bidirectional linking."

  arguments do
    required(:source_id).filled(:string).description("The ID of the source note.")
    required(:target_id).filled(:string).description("The ID of the target note.")
    optional(:link_type).filled(:string).description("The type of link: 'reference', 'extends', 'extended_by', 'refines', 'refined_by', 'contradicts', 'contradicted_by', 'questions', 'questioned_by', 'supports', 'supported_by', or 'related'. Defaults to 'reference'.")
    optional(:description).filled(:string).description("Optional description of the link.")
    optional(:bidirectional).filled(:bool).description("Whether to create a bidirectional link. Defaults to false.")
  end

  def call(source_id:, target_id:, link_type: 'reference', description: nil, bidirectional: false)
    # Initialize service
    service = ZettelService.new
    
    # Create the link
    result = service.create_link(
      source_id: source_id,
      target_id: target_id,
      link_type: link_type,
      description: description,
      bidirectional: bidirectional
    )

    # Return result
    if result.is_a?(Hash) && result[:error]
      { error: result[:error] }
    else
      {
        success: true,
        source_note: result[:source_note],
        target_note: result[:target_note],
        message: "Link created successfully between '#{result[:source_note][:title]}' and '#{result[:target_note]&.dig(:title) || 'target note'}'"
      }
    end
  rescue StandardError => e
    $logger&.error("#{self.class.name}: Error creating link - #{e.class.name}: #{e.message}")
    { error: "Failed to create link: #{e.message}" }
  end
end 