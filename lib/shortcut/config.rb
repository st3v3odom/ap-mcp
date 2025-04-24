# frozen_string_literal: true
# Documentation: https://developer.shortcut.com/api/rest/v3#Introduction

module Shortcut
  module Config
    module_function

    def api_key
      ENV['SHORTCUT_API_TOKEN'] || "***REMOVED***"
    end

    def endpoint
      "https://api.app.shortcut.com/api/v3"
    end

    def base_url
      "https://api.app.shortcut.com"
    end

    def default_group_id
      "61532c5b-f1a2-4ce9-b549-552110ac20db"
    end
  end
end