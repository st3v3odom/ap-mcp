# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'zlib'
require 'stringio'
require 'cgi'
require_relative 'config'

module Supabase
  class Api
    def initialize(use_service_role: false)
      @config = Config
      @config.validate_config!
      
      @base_url = @config.url
      @api_key = use_service_role ? @config.service_role_key : @config.anon_key
      
      # Ensure base_url ends with /rest/v1
      @base_url = @base_url.chomp('/') + '/rest/v1'
      
      $logger&.info("Supabase::Api initialized with base_url: #{@base_url}")
    end

    def get(endpoint, params: {})
      make_request(:GET, endpoint, params: params)
    end

    def post(endpoint, data: nil, params: {})
      make_request(:POST, endpoint, data: data, params: params)
    end

    def put(endpoint, data: nil, params: {})
      make_request(:PUT, endpoint, data: data, params: params)
    end

    def patch(endpoint, data: nil, params: {})
      make_request(:PATCH, endpoint, data: data, params: params)
    end

    def delete(endpoint, params: {})
      make_request(:DELETE, endpoint, params: params)
    end

    private

    def make_request(method, endpoint, data: nil, params: {})
      uri = URI("#{@base_url}#{endpoint}")
      
      # Add query parameters
      if params.any?
        query_params = params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
        uri.query = query_params
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      
      request = case method.to_s.upcase
                when 'GET'
                  Net::HTTP::Get.new(uri)
                when 'POST'
                  Net::HTTP::Post.new(uri)
                when 'PUT'
                  Net::HTTP::Put.new(uri)
                when 'PATCH'
                  Net::HTTP::Patch.new(uri)
                when 'DELETE'
                  Net::HTTP::Delete.new(uri)
                else
                  raise ArgumentError, "Unsupported HTTP method: #{method}"
                end

      # Set headers
      request['apikey'] = @api_key
      request['Authorization'] = "Bearer #{@api_key}"
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
      request['Accept-Encoding'] = 'gzip, deflate'

      # Add request body for POST/PUT/PATCH
      if data && %w[POST PUT PATCH].include?(method.to_s.upcase)
        request.body = data.to_json
      end

      $logger&.debug("Supabase::Api making #{method} request to #{uri}")
      
      begin
        response = http.request(request)
        
        $logger&.debug("Supabase::Api response status: #{response.code}")
        $logger&.debug("Supabase::Api response headers: #{response.to_hash}")
        $logger&.debug("Supabase::Api response body length: #{response.body&.length || 0}")
        
        # Handle gzip compression
        response_body = response.body
        if response['content-encoding'] == 'gzip' && response_body
          begin
            response_body = Zlib::GzipReader.new(StringIO.new(response_body)).read
            $logger&.debug("Supabase::Api: Decompressed gzipped response")
          rescue => e
            $logger&.warn("Supabase::Api: Failed to decompress gzipped response: #{e.message}")
            # If decompression fails, try to use the raw body
            response_body = response.body
          end
        end
        
        # Only try to show preview if response_body is a string
        if response_body.is_a?(String)
          $logger&.debug("Supabase::Api response body preview: #{response_body[0, 100]}")
        else
          $logger&.debug("Supabase::Api response body type: #{response_body.class}")
        end
        
        case response.code
        when '200', '201'
          if response_body && !response_body.empty?
            begin
              JSON.parse(response_body)
            rescue JSON::ParserError => e
              $logger&.warn("Supabase::Api: JSON parse error, returning raw response: #{e.message}")
              response_body
            end
          else
            # Return empty array for empty responses (Supabase standard)
            []
          end
        when '204'
          nil # No content
        else
          error_message = "HTTP #{response.code}: #{response.message}"
          begin
            error_body = JSON.parse(response_body)
            error_message += " - #{error_body['message']}" if error_body['message']
          rescue JSON::ParserError
            error_message += " - #{response_body}" if response_body
          end
          
          $logger&.error("Supabase::Api request failed: #{error_message}")
          raise error_message
        end
      rescue StandardError => e
        $logger&.error("Supabase::Api request error: #{e.class.name}: #{e.message}")
        raise "Supabase API request failed: #{e.message}"
      end
    end
  end
end
