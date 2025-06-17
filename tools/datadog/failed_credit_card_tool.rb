#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'

# Specific tool for failed credit card transactions
class DatadogFailedCreditCardTool < FastMcp::Tool
  include DatadogLogSearchBase

  description "Searches for failed credit card transactions in Datadog logs. Automatically looks for 'Bad request: unable to create transaction' errors and related payment failures."

  arguments do
    optional(:lookback).filled(:string).description("The time period to search back: 'hour', 'day', or 'week'. Defaults to 'week' since credit card issues may need longer investigation.")
    optional(:additional_filters).filled(:string).description("Additional search filters to narrow down results (e.g., account_id, card_id, amount).")
  end

  def call(lookback: 'week', additional_filters: nil)
    # Build the search query specifically for failed credit card transactions
    base_query = 'source:lambda AND ("Bad request: unable to create transaction" OR "unable to create transaction" OR "Insufficient Funds" OR (service:api-production-cardscharge AND status:processor_declined))'

    # Add additional filters if provided
    query = if additional_filters&.strip&.length&.> 0
              "#{base_query} AND #{additional_filters}"
            else
              base_query
            end

    $logger&.info("DatadogFailedCreditCardTool: Searching for failed credit card transactions with query: #{query}")

    # Use a higher page limit for credit card issues since they're important
    search_logs(query, lookback, 50)
  end
end