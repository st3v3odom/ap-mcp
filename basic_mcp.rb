#!/usr/bin/env ruby
# frozen_string_literal: true

require "mcp"
require_relative "lib/shortcut/api"

# Most basic configuration
name "basic-mcp"
version "1.0.0"

# Just one tool
tool "hello" do
  description "Say hello"
  call { "Hello from Basic MCP!" }
end

tool "greet" do
  description "Greet someone by name"
  argument :name, String, required: true, description: "Name to greet"
  call do |args|
    "Hello, #{args[:name]}! Welcome to Ruby MCP."
  end
end

tool "get_story" do
  description "Get a Shortcut story by ID"
  argument :story_id, Integer, required: true, description: "The ID of the story to get"

  call do |args|
    api = Shortcut::Api.new
    begin
      story_id = args[:story_id]
      story = api.get_story(story_id)
      story
    rescue => e
      { error: e.message, backtrace: e.backtrace.first(5) }
    end
  end
end

tool "get_story_from_branch" do
  description "Get a Shortcut story ID from the current git branch name (e.g., sc-12345/...) and fetches the story details."

  call do
    begin
      branch_name = `git branch --show-current`.strip
      match = branch_name.match(/^sc-(\d{5,})\//) # Match sc- followed by 5 or more digits

      unless match
        next { error: "Could not parse story ID from branch name: '#{branch_name}'. Expected format: sc-12345/..." }
      end

      story_id = match[1].to_i
      api = Shortcut::Api.new
      story = api.get_story(story_id)
      story
    rescue => e
      { error: e.message, backtrace: e.backtrace.first(5) }
    end
  end
end

tool "list_epics_by_team" do
  description "List epics by team name"
  argument :team, String, required: true, description: "Team name to filter epics by"
  argument :next_path, String, required: false, description: "Pagination path for next results"

  call do |args|
    api = Shortcut::Api.new
    begin
      epics = api.list_epics_by_team(team: args[:team], next_path: args[:next_path])
      epics
    rescue => e
      { error: e.message, backtrace: e.backtrace.first(5) }
    end
  end
end

tool "get_epic" do
  description "Get a Shortcut epic by ID"
  argument :epic_id, Integer, required: true, description: "The ID of the epic to get"

  call do |args|
    api = Shortcut::Api.new
    begin
      epic = api.get_epic(args[:epic_id])
      epic
    rescue => e
      { error: e.message, backtrace: e.backtrace.first(5) }
    end
  end
end

tool "get_epic_stories" do
  description "Get all stories for a Shortcut epic by ID"
  argument :epic_id, Integer, required: true, description: "The ID of the epic to get stories for"

  call do |args|
    api = Shortcut::Api.new
    begin
      stories = api.get_epic_stories(args[:epic_id])
      stories
    rescue => e
      { error: e.message, backtrace: e.backtrace.first(5) }
    end
  end
end

tool "list_iterations" do
  description "List Shortcut iterations with optional filters"
  argument :completed, String, required: false, description: "Filter by completion status (true/false)"
  argument :started, String, required: false, description: "Filter by started status (true/false)"
  argument :limit, Integer, required: false, description: "Maximum number of results to return"
  argument :offset, Integer, required: false, description: "Number of records to skip"

  call do |args|
    api = Shortcut::Api.new
    begin
      params = {}

      # Convert string 'true'/'false' to actual boolean values
      params[:completed] = args[:completed] == 'true' if args[:completed]
      params[:started] = args[:started] == 'true' if args[:started]
      params[:limit] = args[:limit] if args[:limit]
      params[:offset] = args[:offset] if args[:offset]

      iterations = api.list_iterations(params)
      iterations
    rescue => e
      { error: e.message, backtrace: e.backtrace.first(5) }
    end
  end
end

tool "get_iteration" do
  description "Get a Shortcut iteration by ID"
  argument :iteration_id, Integer, required: true, description: "The ID of the iteration to get"

  call do |args|
    api = Shortcut::Api.new
    begin
      iteration = api.get_iteration(args[:iteration_id])
      iteration
    rescue => e
      { error: e.message, backtrace: e.backtrace.first(5) }
    end
  end
end

tool "get_iteration_stories" do
  description "Get all stories for a Shortcut iteration by ID"
  argument :iteration_id, Integer, required: true, description: "The ID of the iteration to get stories for"

  call do |args|
    api = Shortcut::Api.new
    begin
      stories = api.get_iteration_stories(args[:iteration_id])
      stories
    rescue => e
      { error: e.message, backtrace: e.backtrace.first(5) }
    end
  end
end

tool "search_iterations" do
  description "Search for Shortcut iterations with custom criteria"
  argument :query, String, required: false, description: "Search query string"
  argument :page_size, Integer, required: false, description: "Number of results per page"
  argument :next, String, required: false, description: "Token for the next page of results"

  call do |args|
    api = Shortcut::Api.new
    begin
      iterations = api.search_iterations(args)
      iterations
    rescue => e
      { error: e.message, backtrace: e.backtrace.first(5) }
    end
  end
end

# Enable stdout sync for stdio mode
$stdout.sync = true