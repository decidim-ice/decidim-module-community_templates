# frozen_string_literal: true

require "decidim/community_templates/engine"

module Decidim
  # This namespace holds the logic of the `decidim-community_templates` module.
  module CommunityTemplates
    include ActiveSupport::Configurable

    config_accessor :git_settings do |config|
      config.git_settings = {
        url: "https://example.org/repo/my-template.git",
        branch: "main",
        username: "",
        password: ""
      }
    end
  end
end
