#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../project/project_helper'

# Define the DevLogSearch tool
class DevLogSearchTool < FastMcp::Tool
  include ProjectHelper

  description "Searches the development.log of the active project. Requires 'switch_project' to be called first."

  arguments do
    required(:query).filled(:string).description("The text pattern to search for.")
    optional(:max_results).filled(:integer).description("Maximum matching lines (default 10).")
  end

  def call(query:, max_results: 10)
    active_project_config = load_active_project_config

    unless active_project_config
      $logger.warn("dev_log_search called with no active project.")
      return { error: "No active project. Please use 'switch_project' first." }
    end

    limit = max_results || 10
    project_dir = active_project_config["dir"] || active_project_config[:dir]
    log_rel_path = active_project_config["log"] || active_project_config[:log]

    if project_dir.nil? || log_rel_path.nil?
      $logger.error("Active project dir or log path is not set for dev_log_search. Project config: #{active_project_config}")
      return { error: "Active project dir or log path is not set. Please use 'switch_project' again." }
    end

    log_path = File.join(project_dir, log_rel_path)
    matches = []

    begin
      unless File.exist?(log_path)
        $logger.warn("Log file not found at expected path: #{log_path}")
        return { error: "Log file not found at expected path: #{log_path}" }
      end

      all_lines = File.readlines(log_path, encoding: 'UTF-8', chomp: true)
      all_lines.reverse_each.with_index do |line_content, reverse_idx|
        break if matches.size >= limit

        original_line_number = all_lines.length - reverse_idx

        if line_content.downcase.include?(query.downcase)
          context_before = []
          (1..3).each do |j|
            context_line_array_index = original_line_number - 1 - j
            if context_line_array_index >= 0
              context_before.unshift({
                line_number: context_line_array_index + 1,
                content: all_lines[context_line_array_index]
              })
            end
          end

          matches << {
            line_number: original_line_number,
            content: line_content,
            context_before: context_before
          }
        end
      end
      matches.reverse!

      if matches.empty?
        $logger.info("No matches found for '#{query}' in #{File.basename(log_path)} of project '#{active_project_config[:name]}'")
        { status: "No matches found for '#{query}' in #{File.basename(log_path)} of project '#{active_project_config[:name]}'." }
      else
        $logger.info("Found #{matches.size} matches for '#{query}' in #{log_path}")
        { matches: matches, project: active_project_config[:name], log_file: log_path }
      end

    rescue Errno::EACCES
      $logger.error("Permission denied reading log file: #{log_path}.")
      { error: "Permission denied reading log file: #{log_path}." }
    rescue => e
      $logger.error("Failed to search log file: #{e.message}\n#{e.backtrace.join("\n")}")
      { error: "Failed to search log file: #{e.message}", backtrace: e.backtrace.first(3) }
    end
  end
end