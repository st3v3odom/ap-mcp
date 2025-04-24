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
ruby ruby_mcp_app.rb
```

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

### Greet Tool

Greets a person by name:

```ruby
# Example usage in client code:
result = client.call_tool(
  name: "greet",
  args: {name: "World"}
)
# Returns: "Hello, World! Welcome to Ruby MCP."
```

### Calculate Tool

Performs basic arithmetic operations:

```ruby
# Addition
result = client.call_tool(
  name: "calculate",
  args: {operation: "add", a: 5.0, b: 3.0}
)
# Returns: "Result: 8.0"

# Multiplication
result = client.call_tool(
  name: "calculate",
  args: {operation: "multiply", a: 4.0, b: 7.0}
)
# Returns: "Result: 28.0"

# Division
result = client.call_tool(
  name: "calculate",
  args: {operation: "divide", a: 10.0, b: 2.0}
)
# Returns: "Result: 5.0"

# Subtraction
result = client.call_tool(
  name: "calculate",
  args: {operation: "subtract", a: 10.0, b: 4.0}
)
# Returns: "Result: 6.0"
```

## Extending the Server

To add new tools or resources, edit the `ruby_mcp_app.rb` file:

```ruby
# Add a new tool
tool "new_tool_name" do
  description "Description of what the tool does"
  argument :param_name, Type, required: true, description: "Parameter description"
  call do |args|
    # Tool implementation
  end
end
```

## Debugging

If you encounter any issues, check:
- Correct paths in your MCP configuration
- Proper gem installation
- Tool parameter types (e.g., Float vs Integer)
- **Server running status**: Make sure the MCP server is actually running
- Check the debug log file at `/Users/steveodom/Documents/Projects/mcp-ruby/mcp_app.log`
