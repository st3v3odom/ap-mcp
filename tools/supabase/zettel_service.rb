#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'

# Service for managing Zettelkasten notes
class ZettelService
  include SupabaseBase

  def initialize(use_service_role: true)
    @api = initialize_supabase_api(use_service_role: use_service_role)
    if @api.is_a?(Hash) && @api[:error]
      raise "Failed to initialize Supabase API: #{@api[:error]}"
    end
  end

  # Create a new note
  def create_note(title:, content:, note_type: 'permanent', tags: nil)
    # Validate input
    validation_error = validate_note_data(title: title, content: content, note_type: note_type, tags: tags)
    return validation_error if validation_error

    # Build payload
    payload = build_note_payload(
      title: title,
      content: content,
      note_type: note_type
    )

    # Create note in database
    response = @api.post('/notes', data: payload)
    
    if response.is_a?(Hash) && response[:error]
      return response
    end

    $logger&.debug("ZettelService: POST response type: #{response.class}, value: #{response.inspect}")

    # For POST requests, Supabase typically returns empty body on success
    # We need to fetch the created note to get its details
    if response.nil? || (response.is_a?(Array) && response.empty?) || (response.is_a?(String) && response.strip.empty?)
      $logger&.debug("ZettelService: POST returned empty response, fetching note by title: #{title}")
      # Try to get the note by title to retrieve the created note
      created_note = get_note_by_title(title)
      $logger&.debug("ZettelService: get_note_by_title result: #{created_note.class} - #{created_note}")
      if created_note.is_a?(Hash) && created_note[:error]
        return { error: "Note created but failed to retrieve details: #{created_note[:error]}" }
      end
      note = created_note
    else
      # Extract and return the created note
      note = extract_note_from_response(response)
      $logger&.debug("ZettelService: extract_note_from_response result: #{note.inspect}")
      return { error: "Failed to create note" } unless note
    end

    # Add tags if provided
    if tags && tags.is_a?(Array) && tags.any?
      add_tags_to_note(note[:id], tags)
    end

    handle_supabase_response(note, operation: "Create note")
  end

  # Retrieve a note by ID
  def get_note(note_id)
    return { error: "Note ID is required" } if note_id.nil? || note_id.to_s.strip.empty?

    response = @api.get("/notes", params: { id: "eq.#{note_id}" })
    
    if response.is_a?(Hash) && response[:error]
      return response
    end

    note = extract_note_from_response(response)
    return { error: "Note not found" } unless note

    handle_supabase_response(note, operation: "Get note")
  end

  # Retrieve a note by title
  def get_note_by_title(title)
    return { error: "Title is required" } if title.nil? || title.to_s.strip.empty?

    response = @api.get("/notes", params: { title: "eq.#{title}" })
    
    if response.is_a?(Hash) && response[:error]
      return response
    end

    note = extract_note_from_response(response)
    return { error: "Note not found" } unless note

    handle_supabase_response(note, operation: "Get note by title")
  end

  # Update an existing note
  def update_note(note_id:, title: nil, content: nil, note_type: nil, tags: nil)
    return { error: "Note ID is required" } if note_id.nil? || note_id.to_s.strip.empty?

    # Get existing note first
    existing_note = get_note(note_id)
    return existing_note if existing_note.is_a?(Hash) && existing_note[:error]

    # Build update payload with only provided fields
    update_payload = {}
    update_payload[:title] = sanitize_string_input(title, max_length: 500) if title
    update_payload[:content] = sanitize_string_input(content, max_length: 10000) if content
    update_payload[:note_type] = note_type.to_s.downcase if note_type
    update_payload[:updated_at] = Time.now.iso8601

    # Generate new embedding if title or content changed
    if title || content
      new_title = title || existing_note[:title]
      new_content = content || existing_note[:content]
      embedding_text = "#{new_title}\n\n#{new_content}".strip
      embedding = generate_embedding(embedding_text)
      update_payload[:embedding] = embedding if embedding
    end

    # Update note in database
    response = @api.patch("/notes", data: update_payload, params: { id: "eq.#{note_id}" })
    
    if response.is_a?(Hash) && response[:error]
      return response
    end

    # Handle tags if provided
    if tags && tags.is_a?(Array)
      # For now, we'll just add new tags (in a full implementation, you might want to replace all tags)
      add_tags_to_note(note_id, tags)
    end

    # Get updated note
    updated_note = get_note(note_id)
    return updated_note if updated_note.is_a?(Hash) && updated_note[:error]

    handle_supabase_response(updated_note, operation: "Update note")
  end

  # Delete a note
  def delete_note(note_id)
    return { error: "Note ID is required" } if note_id.nil? || note_id.to_s.strip.empty?

    # First check if note exists
    existing_note = get_note(note_id)
    return existing_note if existing_note.is_a?(Hash) && existing_note[:error]

    # Delete note from database
    response = @api.delete("/notes", params: { id: "eq.#{note_id}" })
    
    if response.is_a?(Hash) && response[:error]
      return response
    end

    handle_supabase_response({ success: true, message: "Note deleted successfully" }, operation: "Delete note")
  end

  # Get all notes
  def get_all_notes(limit: 100, offset: 0)
    response = @api.get("/notes", params: { 
      select: "*",
      order: "updated_at.desc",
      limit: limit,
      offset: offset
    })
    
    if response.is_a?(Hash) && response[:error]
      return response
    end

    notes = extract_notes_from_response(response)
    handle_supabase_response(notes, operation: "Get all notes")
  end

  # Search for notes based on criteria
  def search_notes(query: nil, note_type: nil, tags: nil, limit: 50)
    params = { select: "*", order: "updated_at.desc", limit: limit }
    
    # Add search filters
    if query && !query.to_s.strip.empty?
      params[:or] = "(title.ilike.%#{query}%,content.ilike.%#{query}%)"
    end
    
    if note_type && !note_type.to_s.strip.empty?
      params[:note_type] = "eq.#{note_type}"
    end
    
    # Note: Tag-based search would require more complex joins
    # For now, we'll skip tag filtering until we implement proper joins

    response = @api.get("/notes", params: params)
    
    if response.is_a?(Hash) && response[:error]
      return response
    end

    notes = extract_notes_from_response(response)
    handle_supabase_response(notes, operation: "Search notes")
  end

  # Search for notes using semantic similarity (vector search)
  # def search_notes_semantic(query:, limit: 50, threshold: 0.7)
  #   return { error: "Query is required" } if query.nil? || query.to_s.strip.empty?

  #   # Generate embedding for the query
  #   query_embedding = generate_embedding(query)
  #   return { error: "Failed to generate embedding for query" } unless query_embedding

  #   # Use Supabase's vector similarity search
  #   # Note: This assumes you have pgvector extension enabled and the embedding column is properly indexed
  #   params = {
  #     select: "*",
  #     order: "embedding <-> '[#{query_embedding.join(',')}]'",
  #     limit: limit
  #   }

  #   response = @api.get("/notes", params: params)
    
  #   if response.is_a?(Hash) && response[:error]
  #     return response
  #   end

  #   notes = extract_notes_from_response(response)
    
  #   # Filter by similarity threshold if specified
  #   if threshold > 0
  #     # Note: This is a simplified approach. In a production system, you'd want to
  #     # calculate cosine similarity properly and filter by threshold
  #     notes = notes.select { |note| note[:embedding] } # Only include notes with embeddings
  #   end

  #   handle_supabase_response(notes, operation: "Semantic search notes")
  # end

  # Get notes by tag
  def get_notes_by_tag(tag, limit: 50)
    return { error: "Tag is required" } if tag.nil? || tag.to_s.strip.empty?

    # First, find the tag ID
    tag_response = @api.get("/tags", params: { name: "eq.#{tag}" })
    
    if tag_response.is_a?(Hash) && tag_response[:error]
      return tag_response
    end
    
    if !tag_response.is_a?(Array) || tag_response.empty?
      return { error: "Tag '#{tag}' not found" }
    end
    
    tag_id = tag_response.first['id']
    
    # Get note IDs that have this tag
    note_tags_response = @api.get("/note_tags", params: { 
      tag_id: "eq.#{tag_id}",
      select: "note_id"
    })
    
    if note_tags_response.is_a?(Hash) && note_tags_response[:error]
      return note_tags_response
    end
    
    note_ids = note_tags_response.map { |nt| nt['note_id'] }
    return [] if note_ids.empty?
    
    # Get the actual notes
    note_ids_param = note_ids.map { |id| "id.eq.#{id}" }.join(",")
    notes_response = @api.get("/notes", params: { 
      or: note_ids_param,
      select: "*",
      order: "updated_at.desc",
      limit: limit
    })
    
    if notes_response.is_a?(Hash) && notes_response[:error]
      return notes_response
    end

    notes = extract_notes_from_response(notes_response)
    handle_supabase_response(notes, operation: "Get notes by tag")
  end

  # Add a tag to a note
  def add_tag_to_note(note_id, tag)
    return { error: "Note ID and tag are required" } if note_id.nil? || tag.nil?

    # Get existing note
    existing_note = get_note(note_id)
    return existing_note if existing_note.is_a?(Hash) && existing_note[:error]

    # Add tag if not already present
    current_tags = existing_note[:tags] || []
    return existing_note if current_tags.include?(tag)

    new_tags = current_tags + [tag]
    update_note(note_id: note_id, tags: new_tags)
  end

  # Remove a tag from a note
  def remove_tag_from_note(note_id, tag)
    return { error: "Note ID and tag are required" } if note_id.nil? || tag.nil?

    # Get existing note
    existing_note = get_note(note_id)
    return existing_note if existing_note.is_a?(Hash) && existing_note[:error]

    # Remove tag if present
    current_tags = existing_note[:tags] || []
    return existing_note unless current_tags.include?(tag)

    new_tags = current_tags.reject { |t| t == tag }
    update_note(note_id: note_id, tags: new_tags)
  end

  # Get all tags in the system
  def get_all_tags
    response = @api.get("/tags", params: { select: "*", order: "name.asc" })
    
    if response.is_a?(Hash) && response[:error]
      return response
    end

    tags = extract_tags_from_response(response)
    handle_supabase_response(tags, operation: "Get all tags")
  end

  # Add tags to a note
  def add_tags_to_note(note_id, tag_names)
    return { error: "Note ID and tag names are required" } if note_id.nil? || tag_names.nil?

    added_tags = []
    
    tag_names.each do |tag_name|
      # First, try to find existing tag
      tag_response = @api.get("/tags", params: { name: "eq.#{tag_name}" })
      
      tag_id = nil
      if tag_response.is_a?(Array) && tag_response.any?
        # Tag exists, use its ID
        tag_id = tag_response.first['id']
      else
        # Create new tag
        tag_payload = build_tag_payload(name: tag_name)
        tag_response = @api.post("/tags", data: tag_payload)
        
        if tag_response.is_a?(Hash) && tag_response[:error]
          $logger&.warn("Failed to create tag '#{tag_name}': #{tag_response[:error]}")
          next
        end
        
        tag_id = tag_response.first['id'] if tag_response.is_a?(Array) && tag_response.any?
      end
      
      if tag_id
        # Create note-tag relationship
        note_tag_payload = build_note_tag_payload(note_id: note_id, tag_id: tag_id)
        note_tag_response = @api.post("/note_tags", data: note_tag_payload)
        
        unless note_tag_response.is_a?(Hash) && note_tag_response[:error]
          added_tags << tag_name
        end
      end
    end
    
    { success: true, added_tags: added_tags }
  end

  # Get tags for a specific note
  def get_note_tags(note_id)
    return { error: "Note ID is required" } if note_id.nil?

    response = @api.get("/note_tags", params: { 
      note_id: "eq.#{note_id}",
      select: "tag_id"
    })
    
    if response.is_a?(Hash) && response[:error]
      return response
    end

    # Get tag details for each tag ID
    tag_ids = response.map { |nt| nt['tag_id'] }
    return [] if tag_ids.empty?

    tag_ids_param = tag_ids.map { |id| "id.eq.#{id}" }.join(",")
    tags_response = @api.get("/tags", params: { 
      or: tag_ids_param,
      select: "*"
    })
    
    if tags_response.is_a?(Hash) && tags_response[:error]
      return tags_response
    end

    tags = extract_tags_from_response(tags_response)
    handle_supabase_response(tags, operation: "Get note tags")
  end

  # Create a link between notes
  def create_link(source_id:, target_id:, link_type: 'reference', description: nil, bidirectional: false)
    # Validate input
    validation_error = validate_link_data(source_id: source_id, target_id: target_id, link_type: link_type)
    return validation_error if validation_error

    # Check if notes exist
    source_note = get_note(source_id)
    return source_note if source_note.is_a?(Hash) && source_note[:error]

    target_note = get_note(target_id)
    return target_note if target_note.is_a?(Hash) && target_note[:error]

    # Build link payload
    link_payload = build_link_payload(
      source_id: source_id,
      target_id: target_id,
      link_type: link_type,
      description: description
    )

    # Create link in database
    response = @api.post('/links', data: link_payload)
    
    if response.is_a?(Hash) && response[:error]
      return response
    end

    result = { source_note: source_note, target_note: nil }

    # Handle bidirectional link if requested
    if bidirectional
      # Determine inverse link type
      inverse_map = {
        'reference' => 'reference',
        'extends' => 'extended_by',
        'extended_by' => 'extends',
        'refines' => 'refined_by',
        'refined_by' => 'refines',
        'contradicts' => 'contradicted_by',
        'contradicted_by' => 'contradicts',
        'questions' => 'questioned_by',
        'questioned_by' => 'questions',
        'supports' => 'supported_by',
        'supported_by' => 'supports',
        'related' => 'related'
      }
      
      inverse_type = inverse_map[link_type.to_s.downcase] || link_type
      
      inverse_payload = build_link_payload(
        source_id: target_id,
        target_id: source_id,
        link_type: inverse_type,
        description: description
      )

      inverse_response = @api.post('/links', data: inverse_payload)
      unless inverse_response.is_a?(Hash) && inverse_response[:error]
        result[:target_note] = target_note
      end
    end

    handle_supabase_response(result, operation: "Create link")
  end

  # Remove a link between notes
  def remove_link(source_id:, target_id:, link_type: nil, bidirectional: false)
    return { error: "Source ID and target ID are required" } if source_id.nil? || target_id.nil?

    # Build delete parameters
    params = { source_id: "eq.#{source_id}", target_id: "eq.#{target_id}" }
    params[:link_type] = "eq.#{link_type}" if link_type

    # Remove link from database
    response = @api.delete('/links', params: params)
    
    if response.is_a?(Hash) && response[:error]
      return response
    end

    result = { source_note: nil, target_note: nil }

    # Handle bidirectional removal if requested
    if bidirectional
      inverse_params = { source_id: "eq.#{target_id}", target_id: "eq.#{source_id}" }
      inverse_params[:link_type] = "eq.#{link_type}" if link_type

      inverse_response = @api.delete('/links', params: inverse_params)
      # Don't fail if inverse link doesn't exist
    end

    handle_supabase_response(result, operation: "Remove link")
  end

  # Get notes linked to/from a note
  def get_linked_notes(note_id, direction: 'outgoing')
    return { error: "Note ID is required" } if note_id.nil?

    # Validate direction
    unless %w[outgoing incoming both].include?(direction.to_s.downcase)
      return { error: "Direction must be 'outgoing', 'incoming', or 'both'" }
    end

    # Get links based on direction
    params = {}
    case direction.to_s.downcase
    when 'outgoing'
      params[:source_id] = "eq.#{note_id}"
    when 'incoming'
      params[:target_id] = "eq.#{note_id}"
    when 'both'
      params[:or] = "(source_id.eq.#{note_id},target_id.eq.#{note_id})"
    end

    response = @api.get('/links', params: params)
    
    if response.is_a?(Hash) && response[:error]
      return response
    end

    # Get the actual notes
    note_ids = Set.new
    response.each do |link_data|
      note_ids.add(link_data['source_id']) if link_data['source_id'] != note_id
      note_ids.add(link_data['target_id']) if link_data['target_id'] != note_id
    end

    linked_notes = []
    note_ids.each do |linked_note_id|
      note = get_note(linked_note_id)
      linked_notes << note unless note.is_a?(Hash) && note[:error]
    end

    handle_supabase_response(linked_notes, operation: "Get linked notes")
  end

  # Find notes similar to a given note
  def find_similar_notes(note_id, threshold: 0.3, limit: 5)
    return { error: "Note ID is required" } if note_id.nil?

    # Get the reference note
    reference_note = get_note(note_id)
    return reference_note if reference_note.is_a?(Hash) && reference_note[:error]

    # Get all notes
    all_notes_response = get_all_notes(limit: 1000)
    return all_notes_response if all_notes_response.is_a?(Hash) && all_notes_response[:error]

    all_notes = all_notes_response
    results = []

    # Get reference note's tags and links
    ref_tags = Set.new(reference_note[:tags] || [])
    ref_links = Set.new
    linked_notes_response = get_linked_notes(note_id, direction: 'outgoing')
    unless linked_notes_response.is_a?(Hash) && linked_notes_response[:error]
      linked_notes_response.each { |note| ref_links.add(note[:id]) }
    end

    # Calculate similarity for each note
    all_notes.each do |other_note|
      next if other_note[:id] == note_id

      other_tags = Set.new(other_note[:tags] || [])
      other_links = Set.new
      other_linked_response = get_linked_notes(other_note[:id], direction: 'outgoing')
      unless other_linked_response.is_a?(Hash) && other_linked_response[:error]
        other_linked_response.each { |note| other_links.add(note[:id]) }
      end

      # Calculate similarity score
      tag_overlap = ref_tags.intersection(other_tags).size
      link_overlap = ref_links.intersection(other_links).size
      incoming_overlap = ref_links.include?(other_note[:id]) ? 1 : 0
      outgoing_overlap = other_links.include?(note_id) ? 1 : 0

      total_possible = [
        [ref_tags.size, other_tags.size].max * 0.4,
        [ref_links.size, other_links.size].max * 0.2,
        1 * 0.2,
        1 * 0.2
      ].sum

      similarity = if total_possible > 0
        (tag_overlap * 0.4 + link_overlap * 0.2 + incoming_overlap * 0.2 + outgoing_overlap * 0.2) / total_possible
      else
        0.0
      end

      if similarity >= threshold
        results << { note: other_note, similarity: similarity }
      end
    end

    # Sort by similarity (descending) and limit results
    results.sort_by! { |r| -r[:similarity] }
    results = results.first(limit)

    handle_supabase_response(results, operation: "Find similar notes")
  end

  # Export a note in the specified format
  def export_note(note_id, format: 'markdown')
    return { error: "Note ID is required" } if note_id.nil?

    note = get_note(note_id)
    return note if note.is_a?(Hash) && note[:error]

    case format.to_s.downcase
    when 'markdown'
      content = "# #{note[:title]}\n\n"
      content += "#{note[:content]}\n\n"
      content += "**Type:** #{note[:note_type]}\n"
      content += "**Tags:** #{note[:tags].join(', ')}\n" if note[:tags]&.any?
      content += "**Created:** #{note[:created_at]}\n"
      content += "**Updated:** #{note[:updated_at]}\n"
      
      handle_supabase_response(content, operation: "Export note")
    else
      { error: "Unsupported export format: #{format}" }
    end
  end
end 