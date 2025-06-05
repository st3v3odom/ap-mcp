# External MCP Server

This is a remote-deployable MCP server that provides API-based tools without local file system dependencies. It's designed to be deployed to cloud platforms like Fly.io and accessed by remote MCP clients.

## Available Tools

### RemoteGetStoryTool
- **Description**: Get a Shortcut story by ID
- **Parameters**:
  - `story_id` (required): The ID of the Shortcut story to retrieve
- **Environment Variables**:
  - `SHORTCUT_API_TOKEN`: Your Shortcut API token

### DatadogLogSearchTool
- **Description**: Search Datadog logs using a specified query
- **Parameters**:
  - `query` (required): The search query for Datadog logs
- **Environment Variables**:
  - `DATADOG_API_KEY`: Your Datadog API key
  - `DATADOG_APPLICATION_KEY`: Your Datadog application key

## Deployment to Fly.io

### Prerequisites
1. Install [flyctl](https://fly.io/docs/hands-on/install-flyctl/)
2. Login to Fly.io: `flyctl auth login`
3. Have your API tokens ready (Shortcut, Datadog)

### Deploy
1. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

2. Set your environment variables:
   ```bash
   flyctl secrets set SHORTCUT_API_TOKEN=your-shortcut-token
   flyctl secrets set DD_API_KEY=your-datadog-api-key
   flyctl secrets set DD_APP_KEY=your-datadog-app-key
   ```

### Accessing the Server

Since this server uses stdio transport, it's designed to be accessed via command-line tools or proxies. For remote access from web applications like AnythingLLM, you'll need to use a proxy solution.

#### Option 1: SSH Access
You can SSH into your Fly.io machine and run the server directly:
```bash
flyctl ssh console
ruby external_mcp_server.rb
```

#### Option 2: Use mcp-proxy
For web-based access, consider using [mcp-proxy](https://www.npmjs.com/package/mcp-proxy) to bridge stdio to HTTP/SSE:

```bash
# On your local machine or a server
npx mcp-proxy --port 8080 flyctl ssh console -C "ruby external_mcp_server.rb"
```

## Local Development

### Test the server locally:
```bash
ruby external_mcp_server.rb
```

### Test with MCP Inspector:
```bash
npx @modelcontextprotocol/inspector ruby external_mcp_server.rb
```

## Architecture

This server is specifically designed for external API access and includes only tools that:
- Don't require local file system access
- Work with remote APIs (Shortcut, Datadog)
- Are stateless and can run in containerized environments

The separation from local development tools ensures a clean, secure deployment that only exposes the necessary functionality for remote AI interactions.

## Configuration for MCP Clients

### AnythingLLM
Add this configuration to your AnythingLLM MCP settings:
```json
{
  "mcpServers": {
    "external-mcp": {
      "url": "https://external-mcp-server.fly.dev/sse"
    }
  }
}
```

### Cursor
Add this to your `~/.cursor/mcp.json`:
```json
{
  "mcpServers": {
    "external-mcp": {
      "url": "https://external-mcp-server.fly.dev/sse"
    }
  }
}
```

### Other MCP Clients
Use the SSE endpoint: `https://external-mcp-server.fly.dev/sse`

## Monitoring

Check your server status:
```bash
flyctl status
flyctl logs
```

## Scaling

The server is configured with auto-scaling:
- Minimum 0 machines (scales to zero when not in use)
- Auto-starts when requests come in
- 512MB RAM, 1 shared CPU

You can adjust these settings in `fly.toml` if needed.