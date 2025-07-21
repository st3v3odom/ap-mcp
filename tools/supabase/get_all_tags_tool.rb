#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'
require_relative 'zettel_service'

# Get all tags in the Zettelkasten system
class GetAllTagsTool < FastMcp::Tool
  include SupabaseBase

  description "Retrieves all unique tags used across all Zettelkasten notes."

  arguments do
    # No arguments needed for this tool
  end

  def call
    # Initialize service
    service = ZettelService.new
    
    # Get all tags
    result = service.get_all_tags

    # Return result
    if result.is_a?(Hash) && result[:error]
      { error: result[:error] }
    else
      {
        success: true,
        tags: result,
        count: result.length,
        message: "Found #{result.length} unique tags in the system"
      }
    end
  rescue StandardError => e
    $logger&.error("#{self.class.name}: Error getting all tags - #{e.class.name}: #{e.message}")
    { error: "Failed to get all tags: #{e.message}" }
  end
end 