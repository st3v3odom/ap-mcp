#!/usr/bin/env ruby
# frozen_string_literal: true

# This file serves as the main entry point for all Datadog tools
# It requires all the individual tool files so they can be used together

require_relative 'general_log_search_tool'
require_relative 'failed_credit_card_tool'
