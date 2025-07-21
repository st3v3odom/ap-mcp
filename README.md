# Ruby MCP Demo

It requires ruby 3.3

A simple Ruby MCP (Model Context Protocol) server implementation using the [mcp-rb](https://github.com/funwarioisii/mcp-rb) gem.

## Installation

1. Make sure you have Ruby installed
2. Install the required gem:

```bash
gem install mcp-rb
```

Or use the Gemfile:

```bash
bundle install
```

## Running the Server

You can run the MCP server directly:

```bash
ruby projects.rb --stdio
```

## Dev Changes
kill everything after making a code change.
pkill -f projects.rb && pkill -f shortcut_mcp.rb


You don't need to start it back. Cursor will on demand. You can if you want start it back like:
ruby projects.rb --stdio

### Troubleshooting and Testing
```bash
npx @modelcontextprotocol/inspector /Users/steveodom/.rbenv/shims/ruby /Users/steveodom/Documents/Projects/mcp-ruby/projects.rb
```

And then in your browser:
http://127.0.0.1:6274/#tools

### Running as a Persistent Service

For the MCP server to be available to Cursor and other clients, it needs to be running. You have two options:

1. **Let Cursor launch it automatically**: Cursor will attempt to start the server when needed based on the configuration in mcp.json.

2. **Run it manually in a separate terminal window**:
   ```bash
   # In a dedicated terminal window
   cd /Users/steveodom/Documents/Projects/mcp-ruby
   ruby ruby_mcp_app.rb
   ```
   Keep this terminal open to keep the server running.

3. **Run as a background process**:
   ```bash
   # Start in the background
   cd /Users/steveodom/Documents/Projects/mcp-ruby
   nohup ruby projects.rb --stdio > mcp_server.log 2>&1 &

   # Note the process ID
   echo $! > mcp_server.pid

   # To stop it later
   kill $(cat mcp_server.pid)
   ```

## Testing with the Client

A test client is included to demonstrate how to interact with the MCP server:

```bash
ruby test_client.rb
```

## Cursor Integration

The server has been configured in your Cursor's MCP configuration file:

```json
{
  "ruby-mcp-demo": {
    "command": "ruby",
    "args": [
      "/Users/steveodom/Documents/Projects/mcp-ruby/projects.rb",
      "--stdio",
      "--debug"
    ],
    "enabled": true
  }
}
```

## Available Tools

### Project Management Tools
- `switch_project` - Switch between different projects
- `current_project` - Get information about the current project
- `get_branch` - Get the current git branch name

### Development Tools
- `dev_log_search` - Search development logs
- `local_health` - Check local development environment health

### Shortcut Integration
- `get_story` - Get Shortcut story information

### Datadog Integration
- `log_search` - Search Datadog logs

### Supabase Zettelkasten Tools
- `zk_create_note` - Create a new Zettelkasten note (with automatic embedding generation)
- `zk_get_note` - Retrieve a note by ID or title
- `zk_update_note` - Update an existing note (with automatic embedding regeneration)
- `zk_delete_note` - Delete a note
- `zk_search_notes` - Search notes with various criteria
- `zk_search_notes_semantic` - Search notes using semantic similarity (vector search)
- `zk_create_link` - Create links between notes
- `zk_get_linked_notes` - Get notes linked to/from a note
- `zk_find_similar_notes` - Find similar notes based on tags and links
- `zk_get_all_tags` - Get all tags in the system

## Embedding Support

The Zettelkasten system now supports automatic embedding generation for semantic search capabilities:

### Setup
1. Add your OpenAI API key to your environment variables:
   ```bash
   export OPENAI_API_KEY="your-openai-api-key-here"
   ```

2. Ensure your Supabase database has the `embedding` column in the `notes` table with the appropriate vector type (e.g., `vector(1536)` for OpenAI embeddings).

3. Install the pgvector extension in your Supabase database if not already installed.

### Features
- **Automatic Embedding Generation**: When creating or updating notes, embeddings are automatically generated from the combined title and content
- **Semantic Search**: Use `zk_search_notes_semantic` to find notes based on semantic similarity rather than just keyword matching
- **Vector Storage**: Embeddings are stored as vectors in the database for efficient similarity calculations

### Usage
```ruby
# Create a note (embedding generated automatically)
service.create_note(
  title: "Machine Learning Basics",
  content: "Introduction to supervised and unsupervised learning...",
  note_type: "permanent"
)

# Search semantically
similar_notes = service.search_notes_semantic(
  query: "artificial intelligence concepts",
  limit: 10,
  threshold: 0.7
)
```

