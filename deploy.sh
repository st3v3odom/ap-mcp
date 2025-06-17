#!/bin/bash

# Deploy External MCP Server to Fly.io

echo "🚀 Deploying External MCP Server to Fly.io..."

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    echo "❌ flyctl is not installed. Please install it first:"
    echo "   curl -L https://fly.io/install.sh | sh"
    exit 1
fi

# Check if user is logged in
if ! flyctl auth whoami &> /dev/null; then
    echo "❌ Not logged in to Fly.io. Please run: flyctl auth login"
    exit 1
fi

# Deploy the app
echo "📦 Building and deploying..."
flyctl deploy

echo "✅ Deployment complete!"
echo ""
echo "🔗 Your MCP server is now running on Fly.io"
echo ""
echo "📋 To use with AnythingLLM or other MCP clients:"
echo "   Since this uses stdio transport, you'll need to connect via SSH or use a proxy"
echo "   Consider using mcp-proxy or similar tools for remote access"
echo ""
echo "🛠️  Available tools:"
echo "   - RemoteGetStoryTool: Get Shortcut stories by ID"
echo "   - DatadogLogSearchTool: Search Datadog logs"
echo "   - DatadogFailedCreditCardTool: Search for failed credit card transactions"
echo ""
echo "🔧 Environment variables to set:"
echo "   flyctl secrets set SHORTCUT_API_TOKEN=your-token"
echo "   flyctl secrets set DATADOG_API_KEY=your-datadog-api-key"
echo "   flyctl secrets set DATADOG_APP_KEY=your-datadog-app-key"