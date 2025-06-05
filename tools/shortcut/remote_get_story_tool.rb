#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/shortcut/api'
require 'fast_mcp'

# Define the RemoteGetStory tool for Shortcut (remote-friendly version)
class RemoteGetStoryTool < FastMcp::Tool
  description "Get a Shortcut story by ID. This is a remote-friendly version that requires an explicit story ID."

  arguments do
    required(:story_id).filled(:integer).description("The ID of the Shortcut story to retrieve.")
  end

  def call(story_id:)
    api = Shortcut::Api.new
    begin
      story = api.get_story(story_id)
      $logger.info("Successfully retrieved Shortcut story #{story_id}")
      story
    rescue StandardError => e
      $logger.error("Error getting story #{story_id}: #{e.message}")
      { error: e.message, backtrace: e.backtrace.first(5) }
    end
  end
end