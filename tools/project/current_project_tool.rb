#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'project_helper'

# Define the CurrentProject tool
class CurrentProjectTool < FastMcp::Tool
  include ProjectHelper

  description "Shows the currently active project context."

  arguments do
    # No arguments needed
  end

  def call
    active_project_config = load_active_project_config

    if active_project_config
      $logger.info("Current project: #{active_project_config}")
      { active_project: active_project_config }
    else
      $logger.warn("No active project set when calling current_project.")
      { status: "No active project. Use 'switch_project' to select one." }
    end
  end
end