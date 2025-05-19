#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/shortcut/api'
require_relative '../project/project_helper'
require 'fast_mcp'

# Define the GetStory tool for Shortcut
class GetStoryTool < FastMcp::Tool
  include ProjectHelper

  description "Get a Shortcut story by ID. If story_id is not provided, attempts to derive from the current git branch (e.g., sc-12345/...)."

  arguments do
    optional(:story_id).filled(:integer).description("The ID of the story to get. If not provided, attempts to derive from current git branch (e.g., sc-12345/...).")
  end

  def call(story_id: nil)
    final_story_id = story_id

    if final_story_id.nil?
      $logger.info("Story ID not provided, attempting to derive from git branch.")
      active_project_config = load_active_project_config

      unless active_project_config
        $logger.warn("GetStoryTool: No active project. Cannot derive story ID from branch.")
        return { error: "No active project. Please use 'switch_project' first or provide a story_id." }
      end

      project_dir = active_project_config[:dir] || active_project_config["dir"]

      unless project_dir && Dir.exist?(project_dir)
        $logger.error("GetStoryTool: Active project dir '#{project_dir}' is not set or does not exist. Project config: #{active_project_config}")
        return { error: "Active project directory not configured or does not exist. Cannot derive story ID. Please use 'switch_project' again or provide a story_id." }
      end

      current_branch = `git -C "#{project_dir}" rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
      if $?.success? && !current_branch.empty? && current_branch != 'HEAD'
        match_data = current_branch.match(/\Asc-(\d+)/)
        if match_data && match_data[1]
          final_story_id = match_data[1].to_i
          $logger.info("Derived story ID #{final_story_id} from branch '#{current_branch}' in project '#{active_project_config[:name]}'.")
        else
          $logger.warn("Could not derive story ID from branch '#{current_branch}' in project '#{active_project_config[:name]}'. Branch name does not match 'sc-XXXXX/...' pattern.")
        end
      else
        status_message = if !$?.success?
                           "Git command failed"
                         elsif current_branch == 'HEAD'
                           "HEAD is detached"
                         else
                           "No branch name found"
                         end
        $logger.warn("#{status_message} in project: #{active_project_config[:name]}. Cannot derive story ID.")
      end
    end

    unless final_story_id
      return { error: "Story ID not provided and could not be derived from the current Git branch. Please provide a story_id or checkout a branch named like 'sc-12345/your-feature'." }
    end

    api = Shortcut::Api.new
    begin
      story = api.get_story(final_story_id)
      story
    rescue StandardError => e
      $logger.error("Error getting story #{final_story_id}: #{e.message}")
      { error: e.message, backtrace: e.backtrace.first(5) }
    end
  end
end