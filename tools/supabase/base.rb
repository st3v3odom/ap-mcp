#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fast_mcp'
require_relative '../../lib/supabase/api'
require 'openai'

# Shared module for common Supabase functionality
module SupabaseBase
  private

  def initialize_supabase_api(use_service_role: false)
    begin
      supabase_api = Supabase::Api.new(use_service_role: use_service_role)
    rescue StandardError => e
      $logger&.error("#{self.class.name}: Failed to initialize Supabase::Api - #{e.class.name}: #{e.message}")
      return { error: "Failed to initialize Supabase API: #{e.message}" }
    end

    # Verify that API keys are effectively available via Supabase::Config
    unless Supabase::Config.url && Supabase::Config.anon_key
      $logger&.warn("#{self.class.name}: SUPABASE_URL or SUPABASE_ANON_KEY environment variables not set or not accessible via Supabase::Config.")
      return { error: "Supabase URL (SUPABASE_URL) and API key (SUPABASE_ANON_KEY) must be set in environment variables." }
    end

    supabase_api
  end

  def initialize_openai_client
    return nil unless ENV['OPENAI_API_KEY']
    
    begin
      OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    rescue StandardError => e
      $logger&.error("#{self.class.name}: Failed to initialize OpenAI client - #{e.class.name}: #{e.message}")
      nil
    end
  end

  def generate_embedding(text, model: 'text-embedding-3-small')
    return nil if text.nil? || text.to_s.strip.empty?
    
    client = initialize_openai_client
    return nil unless client
    
    begin
      # Prepare text for embedding (combine title and content if both provided)
      embedding_text = text.to_s.strip
      
      # Truncate if too long (OpenAI has limits)
      max_tokens = 8000 # Conservative limit for text-embedding-3-small
      if embedding_text.length > max_tokens * 4 # Rough estimate: 1 token ≈ 4 characters
        embedding_text = embedding_text[0, max_tokens * 4]
        $logger&.warn("#{self.class.name}: Text truncated for embedding generation")
      end
      
      response = client.embeddings(
        parameters: {
          model: model,
          input: embedding_text
        }
      )
      
      if response&.dig('data', 0, 'embedding')
        $logger&.debug("#{self.class.name}: Successfully generated embedding with #{response['data'][0]['embedding'].length} dimensions")
        return response['data'][0]['embedding']
      else
        $logger&.error("#{self.class.name}: Failed to generate embedding - invalid response format")
        return nil
      end
    rescue StandardError => e
      $logger&.error("#{self.class.name}: Failed to generate embedding - #{e.class.name}: #{e.message}")
      nil
    end
  end

  def handle_supabase_response(response, operation: "Supabase operation")
    if response.is_a?(Hash) && response[:error]
      $logger&.error("#{self.class.name}: #{operation} failed - #{response[:error]}")
      return response
    end

    $logger&.info("#{self.class.name}: #{operation} completed successfully")
    response
  rescue StandardError => e
    $logger&.error("#{self.class.name}: #{operation} error - #{e.class.name}: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n  ")}")
    { error: "An unexpected error occurred during #{operation.downcase}: #{e.message}" }
  end

  def validate_required_params(params, required_keys)
    missing_keys = required_keys.select { |key| params[key].nil? || params[key].to_s.strip.empty? }
    
    if missing_keys.any?
      error_msg = "Missing required parameters: #{missing_keys.join(', ')}"
      $logger&.error("#{self.class.name}: #{error_msg}")
      return { error: error_msg }
    end
    
    nil # No error
  end

  def sanitize_string_input(input, max_length: 1000)
    return nil if input.nil?
    
    sanitized = input.to_s.strip
    if sanitized.length > max_length
      $logger&.warn("#{self.class.name}: Input truncated from #{sanitized.length} to #{max_length} characters")
      sanitized = sanitized[0, max_length]
    end
    
    sanitized
  end

  def format_timestamp(timestamp)
    return timestamp if timestamp.is_a?(String)
    return timestamp.iso8601 if timestamp.respond_to?(:iso8601)
    timestamp.to_s
  end

  def parse_json_safely(json_string)
    return nil if json_string.nil? || json_string.to_s.strip.empty?
    
    JSON.parse(json_string.to_s)
  rescue JSON::ParserError => e
    $logger&.error("#{self.class.name}: Failed to parse JSON - #{e.message}")
    nil
  end

  # Zettelkasten-specific helper methods
  def validate_note_data(title:, content:, note_type: 'permanent', tags: nil)
    validation_error = validate_required_params({ title: title, content: content }, [:title, :content])
    return validation_error if validation_error

    # Validate note type
    valid_types = %w[permanent fleeting literature structure hub]
    unless valid_types.include?(note_type.to_s.downcase)
      return { error: "Invalid note type. Must be one of: #{valid_types.join(', ')}" }
    end

    # Validate tags if provided
    if tags && !tags.is_a?(Array)
      return { error: "Tags must be an array of strings" }
    end

    nil # No validation errors
  end

  def validate_link_data(source_id:, target_id:, link_type: 'reference')
    validation_error = validate_required_params({ source_id: source_id, target_id: target_id }, [:source_id, :target_id])
    return validation_error if validation_error

    # Validate link type
    valid_types = %w[reference extends extended_by refines refined_by contradicts contradicted_by questions questioned_by supports supported_by related]
    unless valid_types.include?(link_type.to_s.downcase)
      return { error: "Invalid link type. Must be one of: #{valid_types.join(', ')}" }
    end

    # Ensure source and target are different
    if source_id == target_id
      return { error: "Source and target note IDs must be different" }
    end

    nil # No validation errors
  end

  def build_note_payload(title:, content:, note_type: 'permanent')
    # Generate embedding from title and content
    embedding_text = "#{title}\n\n#{content}".strip
    embedding = generate_embedding(embedding_text)
    
    payload = {
      title: sanitize_string_input(title, max_length: 500),
      content: sanitize_string_input(content, max_length: 10000),
      note_type: note_type.to_s.downcase,
      created_at: Time.now.iso8601,
      updated_at: Time.now.iso8601
    }
    
    # Add embedding if successfully generated
    payload[:embedding] = embedding if embedding
    
    payload
  end

  def build_tag_payload(name:)
    {
      name: sanitize_string_input(name, max_length: 100),
      created_at: Time.now.iso8601
    }
  end

  def build_note_tag_payload(note_id:, tag_id:)
    {
      note_id: note_id,
      tag_id: tag_id,
      created_at: Time.now.iso8601
    }
  end

  def build_link_payload(source_id:, target_id:, link_type: 'reference', description: nil)
    {
      source_id: source_id,
      target_id: target_id,
      link_type: link_type.to_s.downcase,
      description: sanitize_string_input(description, max_length: 500),
      created_at: Time.now.iso8601
    }
  end

  def extract_note_from_response(response)
    return nil unless response
    
    # Handle different response formats
    note_data = case response
    when Array
      return nil unless response.any?
      response.first
    when Hash
      response
    else
      return nil
    end
    
    {
      id: note_data['id'],
      title: note_data['title'],
      content: note_data['content'],
      note_type: note_data['note_type'],
      embedding: note_data['embedding'],
      created_at: note_data['created_at'],
      updated_at: note_data['updated_at']
    }
  end

  def extract_notes_from_response(response)
    return [] unless response && response.is_a?(Array)
    
    response.map do |note_data|
      {
        id: note_data['id'],
        title: note_data['title'],
        content: note_data['content'],
        note_type: note_data['note_type'],
        embedding: note_data['embedding'],
        created_at: note_data['created_at'],
        updated_at: note_data['updated_at']
      }
    end
  end

  def extract_tags_from_response(response)
    return [] unless response && response.is_a?(Array)
    
    response.map do |tag_data|
      {
        id: tag_data['id'],
        name: tag_data['name'],
        created_at: tag_data['created_at']
      }
    end
  end
end 