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
ruby basic_app.rb
```

## Dev Changes
kill everything after making a code change.
pkill -f projects.rb && pkill -f shortcut_mcp.rb


You don't need to start it back. Cursor will on demand. You can if you want start it back lik:
ruby project_mcp.rb --stdio

### Troubleshooting and Testing
`npx @modelcontextprotocol/inspector /Users/steveodom/.rbenv/shims/ru
by /Users/steveodom/Documents/Projects/mcp-ruby/projects.rb`

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
   nohup ruby ruby_mcp_app.rb > mcp_server.log 2>&1 &

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
      "/Users/steveodom/Documents/Projects/mcp-ruby/ruby_mcp_app.rb",
      "--stdio",
      "--debug"
    ],
    "enabled": true
  }
}
```

## Available Tools

