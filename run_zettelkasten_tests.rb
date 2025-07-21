#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv'

# Load environment variables
Dotenv.load

def show_help
  puts "🧪 Zettelkasten Test Runner"
  puts "=" * 40
  puts "Usage: ruby run_zettelkasten_tests.rb [option]"
  puts ""
  puts "Options:"
  puts "  --comprehensive    Run all comprehensive tests (default)"
  puts "  --basic            Run basic workflow tests"
  puts "  --interactive      Run interactive test mode"
  puts "  --help             Show this help message"
  puts ""
  puts "Examples:"
  puts "  ruby run_zettelkasten_tests.rb --comprehensive"
  puts "  ruby run_zettelkasten_tests.rb --basic"
  puts "  ruby run_zettelkasten_tests.rb --interactive"
end

def run_comprehensive_tests
  puts "Running comprehensive tests..."
  load 'test_zettelkasten_comprehensive.rb'
end

# def run_embedding_tests
#   puts "Running embedding tests..."
#   load 'test_embedding.rb'
# end

def run_basic_tests
  puts "Running basic workflow tests..."
  load 'test_mcp_tools.rb'
  
  # Run the basic workflow
  test_full_workflow
end

def run_interactive_tests
  puts "Starting interactive test mode..."
  load 'interactive_test.rb'
end

# Main execution
case ARGV.first
when '--comprehensive', nil
  run_comprehensive_tests
when '--basic'
  run_basic_tests
when '--interactive'
  run_interactive_tests
when '--help', '-h'
  show_help
else
  puts "Unknown option: #{ARGV.first}"
  show_help
end 