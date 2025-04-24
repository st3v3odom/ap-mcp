require_relative "config"
require "rest-client"
require "json"

module Shortcut
  class Api
    def initialize
      @resource = RestClient::Resource.new(Shortcut::Config.endpoint, headers: headers)
    end

    # https://developer.shortcut.com/api/rest/v3#Epics
    # The response is a JSON object with data, next, and total keys.
    # https://developer.shortcut.com/api/rest/v3#EpicSearchResult
    def list_epics_by_team(team: "Accounts", next_path: nil)
      RestClient.log = STDOUT

      if next_path # pagination url returned by the endpoint
        response = RestClient.get("#{Shortcut::Config.base_url}#{next_path}", headers)
      else
        search_params = {
          "query": "team:#{team}",
          "page_size": 25
        }
        response = @resource["/search/epics"].get(params: search_params)
      end

      JSON.parse(response.body)
    end

    def get_epic(epic_id)
      # Get the details for a specific epic
      response = @resource["/epics/#{epic_id}"].get
      JSON.parse(response.body)
    end

    def get_epic_stories(epic_id)
      # Get the list of stories for this epic
      response = @resource["/epics/#{epic_id}/stories"].get
      stories = JSON.parse(response.body)

      # For each story, fetch its complete details
      stories.map do |story|
        puts "Fetching details for story #{story['id']}"
        get_story(story['id'])
      end
    end

    def get_story(story_id)
      response = @resource["/stories/#{story_id}"].get
      JSON.parse(response.body)
    end

    # https://developer.shortcut.com/api/rest/v3#List-Iterations
    # Fetches all iterations, with optional parameters for filtering
    def list_iterations(params = {})
      query_params = {}

      # Add optional params if they are provided
      query_params[:completed] = params[:completed] unless params[:completed].nil?
      query_params[:started] = params[:started] unless params[:started].nil?
      query_params[:limit] = params[:limit] if params[:limit]
      query_params[:offset] = params[:offset] if params[:offset]

      # Make the API call
      if query_params.empty?
        response = @resource["/iterations"].get
      else
        response = @resource["/iterations"].get(params: query_params)
      end

      JSON.parse(response.body)
    end

    # https://developer.shortcut.com/api/rest/v3#Get-Iteration
    # Fetches details for a specific iteration by ID
    def get_iteration(iteration_id)
      response = @resource["/iterations/#{iteration_id}"].get
      JSON.parse(response.body)
    end

    # https://developer.shortcut.com/api/rest/v3#List-Stories-in-Iteration
    # Fetches stories for a specific iteration
    def get_iteration_stories(iteration_id)
      response = @resource["/iterations/#{iteration_id}/stories"].get
      stories = JSON.parse(response.body)

      # For each story, fetch its complete details
      stories.map do |story|
        puts "Fetching details for story #{story['id']}"
        get_story(story['id'])
      end
    end

    # https://developer.shortcut.com/api/rest/v3#Search-Iterations
    # Searches for iterations with custom criteria
    def search_iterations(params = {})
      search_params = {}

      # Add query parameters if provided
      search_params[:query] = params[:query] if params[:query]
      search_params[:page_size] = params[:page_size] if params[:page_size]
      search_params[:next] = params[:next] if params[:next]

      response = @resource["/search/iterations"].get(params: search_params)
      JSON.parse(response.body)
    end

    private

    def headers
      {
        "Shortcut-Token" => Shortcut::Config.api_key,
        "Content-Type" => "application/json"
      }
    end
  end
end