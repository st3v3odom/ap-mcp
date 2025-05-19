#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fast_mcp'
require_relative '../project/project_helper'

# Define the GetBranchTool
class GetBranchTool < FastMcp::Tool
  include ProjectHelper

  description "Gets the current git branch name for the active project's directory."

  def call
    active_project_config = load_active_project_config

    unless active_project_config
      $logger.warn("GetBranchTool called with no active project.")
      return { error: "No active project. Please use 'switch_project' first." }
    end

    project_dir = active_project_config[:dir] || active_project_config["dir"]

    if project_dir.nil?
      $logger.error("Active project dir is not set for GetBranchTool. Project config: #{active_project_config}")
      return { error: "Active project dir is not set. Please use 'switch_project' again." }
    end

    unless Dir.exist?(project_dir)
      $logger.error("Active project directory does not exist: #{project_dir}")
      return { error: "Active project directory does not exist: #{project_dir}" }
    end

    # Execute the git command in the context of the active project's directory
    branch_name = `git -C "#{project_dir}" rev-parse --abbrev-ref HEAD 2>/dev/null`.strip

    if $?.success?
      if branch_name.empty?
        { status: "HEAD is detached or no branch name found in project: #{active_project_config[:name]}." }
      else
        { project: active_project_config[:name], branch: branch_name }
      end
    else
      { error: "Not a git repository, no branch checked out, or git command failed in project: #{active_project_config[:name]}." }
    end
  rescue StandardError => e
    $logger.error("Error in GetBranchTool: #{e.message} for project_dir: #{project_dir}")
    { error: "An unexpected error occurred: #{e.message}" }
  end
end