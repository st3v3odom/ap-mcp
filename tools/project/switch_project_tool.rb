#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'project_helper'

# Define the SwitchProject tool
class SwitchProjectTool < FastMcp::Tool
  include ProjectHelper

  description "Switches the active project context. Projects are defined in projects.yml."

  arguments do
    required(:project_name).filled(:string).description("The friendly name of the project from projects.yml")
  end

  def call(project_name:)
    projects = load_projects_config

    if projects.key?(project_name)
      project_info = projects[project_name]
      active_project_config = {
        name: project_name,
        dir: project_info["dir"] || project_info[:dir],
        log: project_info["log"] || project_info[:log]
      }

      File.write(ACTIVE_PROJECT_FILE, active_project_config.to_yaml)
      $logger.info("Switched to project '#{project_name}' at dir '#{active_project_config[:dir]}' with log '#{active_project_config[:log]}'")

      { status: "Switched to project '#{project_name}' at dir '#{active_project_config[:dir]}' with log '#{active_project_config[:log]}'" }
    else
      File.delete(ACTIVE_PROJECT_FILE) if File.exist?(ACTIVE_PROJECT_FILE)
      $logger.warn("Project '#{project_name}' not found in projects.yml. Available: #{projects.keys.join(', ')}")

      { error: "Project '#{project_name}' not found in projects.yml. Available: #{projects.keys.join(', ')}" }
    end
  end
end