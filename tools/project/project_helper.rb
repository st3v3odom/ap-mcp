#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'logger'

# Helper module for project configuration
module ProjectHelper
  PROJECTS_CONFIG_FILE = File.expand_path('../../projects.yml', __dir__)
  ACTIVE_PROJECT_FILE = File.expand_path('../../.active_project.yml', __dir__)

  def load_projects_config
    unless File.exist?(PROJECTS_CONFIG_FILE)
      $logger.warn("projects.yml does not exist at #{PROJECTS_CONFIG_FILE}")
      return {}
    end

    YAML.load_file(PROJECTS_CONFIG_FILE) || {}
  rescue Psych::SyntaxError => e
    $logger.error("Error parsing projects.yml: #{e.message}")
    {}
  rescue => e
    $logger.error("Unexpected error in load_projects_config: #{e.class} - #{e.message}")
    {}
  end

  def load_active_project_config
    if File.exist?(ACTIVE_PROJECT_FILE)
      YAML.load_file(ACTIVE_PROJECT_FILE)
    else
      nil
    end
  rescue Psych::SyntaxError => e
    $logger.error("Error parsing .active_project.yml: #{e.message}")
    nil
  end
end