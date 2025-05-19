#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'json' # For parsing tilt dump engine if needed, or just for general utility
require_relative '../project/project_helper'

# Define the LocalDevClusterHealthTool
class LocalHealthTool < FastMcp::Tool
  include ProjectHelper

  description "Fetches diagnostic information from the local k3d/Tilt/Doppler development environment for the active project."

  COMMON_ENV_VARS = { "LANG" => "en_US.UTF-8", "LC_ALL" => "en_US.UTF-8" }.freeze

  def call
    active_project_config = load_active_project_config
    unless active_project_config
      $logger.warn("LocalHealthTool called with no active project.")
      return { error: "No active project. Please use 'switch_project' first." }
    end

    project_dir = active_project_config["dir"] || active_project_config[:dir]
    project_name = active_project_config["name"] || active_project_config[:name]

    if project_dir.nil?
      $logger.error("Active project dir is not set for LocalHealthTool. Project config: #{active_project_config}")
      return { error: "Active project dir is not set for project '#{project_name}'. Please use 'switch_project' again." }
    end

    results = { project_name: project_name, checks: {} }
    original_dir = Dir.pwd

    determined_tilt_exe = determine_working_tilt_command(results)
    $logger.info("LocalHealthTool: Effective Tilt command determined: '#{determined_tilt_exe || 'NONE FOUND'}'")

    commands_to_run_config = {
      k3d_cluster_list: { cmd_str: "k3d cluster list" },
      doppler_whoami: { cmd_str: "doppler whoami" },
      kubectl_pods_all: { cmd_str: "kubectl get pods -A" }
    }

    if determined_tilt_exe
      commands_to_run_config[:tilt_version] = { cmd_str: "#{determined_tilt_exe} version" }
      commands_to_run_config[:tilt_doctor] = { cmd_str: "#{determined_tilt_exe} doctor" }
      commands_to_run_config[:tilt_dump_engine] = { cmd_str: "#{determined_tilt_exe} dump engine" }
    else
      results[:checks][:tilt_setup_error] = {
        status: 'error', output: nil,
        error_details: "Could not determine a working 'tilt' or 'ctilt' command. Tilt-specific checks will be skipped."
      }
      $logger.error("LocalHealthTool: No working Tilt command found. Skipping Tilt-specific checks.")
    end

    begin
      Dir.chdir(project_dir)
      $logger.info("LocalHealthTool: Changed directory to '#{project_dir}' for project '#{project_name}'.")

      commands_to_run_config.each do |key, config|
        cmd_parts = config[:cmd_str].shellsplit # Use shellsplit for better parsing
        exe = cmd_parts.first
        args = cmd_parts.drop(1)
        command_to_log = config[:cmd_str]

        $logger.debug("LocalHealthTool: Executing command for '#{key}': #{command_to_log} (exe: '#{exe}', args: #{args.inspect}) with env #{COMMON_ENV_VARS.inspect}")

        stdout_stderr, status = Open3.capture2e(COMMON_ENV_VARS, exe, *args)

        # Output sanitization
        raw_output = stdout_stderr
        raw_output.force_encoding('UTF-8')
        unless raw_output.valid_encoding?
          $logger.warn("LocalHealthTool: Output from '#{command_to_log}' is not valid UTF-8 after force_encoding. Original encoding: #{raw_output.encoding.name}. Attempting to transcode, replacing errors.")
          raw_output = raw_output.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
        end
        output_stripped = raw_output.strip

        if status.success?
          results[:checks][key] = { status: 'success', output: output_stripped }
          output_summary = output_stripped.lines.first(5).map(&:strip).join('; ')
          $logger.info("LocalHealthTool: Command '#{command_to_log}' succeeded. Output summary: #{output_summary}...")
        else
          error_message = "Command '#{command_to_log}' failed with status #{status.exitstatus}."
          results[:checks][key] = { status: 'error', output: output_stripped, error_details: error_message }
          $logger.warn("LocalHealthTool: #{error_message} Output: #{output_stripped}")
        end
      rescue Errno::ENOENT => e
        error_message = "Command '#{exe}' for '#{key}' not found. Error: #{e.message}"
        results[:checks][key] = { status: 'error', output: nil, error_details: error_message }
        $logger.error("LocalHealthTool: #{error_message}")
      rescue => e
        error_message = "Error executing command '#{command_to_log}': #{e.message}"
        results[:checks][key] = { status: 'error', output: nil, error_details: error_message, backtrace: e.backtrace.first(5) }
        $logger.error("LocalHealthTool: #{error_message}\n#{e.backtrace.join("\n")}")
      end
    ensure
      Dir.chdir(original_dir)
      $logger.info("LocalHealthTool: Changed directory back to '#{original_dir}'.")
    end

    $logger.info("LocalHealthTool finished for project '#{project_name}'.")
    results
  end

  private

  def determine_working_tilt_command(results_hash)
    tilt_commands_to_try = ["tilt", "ctilt"]

    tilt_commands_to_try.each_with_index do |tilt_cmd_exe, index|
      check_key = "tilt_determination_attempt_#{index + 1}_#{tilt_cmd_exe}".to_sym
      command_to_log_for_determination = "#{tilt_cmd_exe} version"
      begin
        $logger.info("LocalHealthTool: Attempting to determine working Tilt command with: '#{command_to_log_for_determination}' using env #{COMMON_ENV_VARS.inspect}")
        stdout_stderr, status = Open3.capture2e(COMMON_ENV_VARS, tilt_cmd_exe, "version")

        # Output sanitization for determination step as well
        raw_output = stdout_stderr
        raw_output.force_encoding('UTF-8')
        unless raw_output.valid_encoding?
          $logger.warn("LocalHealthTool (determination): Output from '#{command_to_log_for_determination}' is not valid UTF-8. Original encoding: #{raw_output.encoding.name}. Attempting to transcode.")
          raw_output = raw_output.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
        end
        output_stripped = raw_output.strip

        if status.success?
          # Further check if the output looks like a tilt-dev version
          if output_stripped.match?(/v\d+\.\d+\.\d+/)
            $logger.info("LocalHealthTool: '#{command_to_log_for_determination}' succeeded and output matches version pattern. Using '#{tilt_cmd_exe}'. Output: #{output_stripped}")
            results_hash[:checks][check_key] = { status: 'success_found_command', command_used: tilt_cmd_exe, output: output_stripped }
            return tilt_cmd_exe
          else
            $logger.warn("LocalHealthTool: '#{command_to_log_for_determination}' succeeded but output '#{output_stripped}' does not look like a tilt-dev version. Not using this.")
            results_hash[:checks][check_key] = { status: 'failure_output_mismatch', command_used: tilt_cmd_exe, output: output_stripped, exit_status: status.exitstatus }
          end
        else
          $logger.warn("LocalHealthTool: '#{command_to_log_for_determination}' failed or non-zero exit. Status: #{status.exitstatus}. Output: #{output_stripped}")
          results_hash[:checks][check_key] = { status: 'failure_to_verify', command_used: tilt_cmd_exe, output: output_stripped, exit_status: status.exitstatus }
        end
      rescue Errno::ENOENT
        $logger.warn("LocalHealthTool: Command '#{tilt_cmd_exe}' not found during Tilt determination.")
        results_hash[:checks][check_key] = { status: 'command_not_found', command_used: tilt_cmd_exe }
      rescue => e
        $logger.error("LocalHealthTool: Error while trying '#{command_to_log_for_determination}': #{e.message}")
        results_hash[:checks][check_key] = { status: 'error_during_determination', command_used: tilt_cmd_exe, error_message: e.message }
      end
    end
    nil
  end
end

# Add shellsplit to String if not already defined (e.g. older Ruby versions)
# For Ruby 2.7+ (FastMcP environment likely), Shellwords.shellsplit is available
require 'shellwords'
unless String.method_defined?(:shellsplit)
  class String
    def shellsplit
      Shellwords.shellsplit(self)
    end
  end
end