# frozen_string_literal: true

require "git"
require "decidim/community_templates/engine"
require "decidim/community_templates/git_mirror"

module Decidim
  # This namespace holds the logic of the `decidim-community_templates` module.
  module CommunityTemplates
    include ActiveSupport::Configurable

    config_accessor :git_settings do
      {
        url: ENV.fetch("TEMPLATE_GIT_URL", "https://example.org/repo/my-template.git"),
        branch: ENV.fetch("TEMPLATE_GIT_BRANCH", "main"),
        username: ENV.fetch("TEMPLATE_GIT_USERNAME", ""),
        password: ENV.fetch("TEMPLATE_GIT_PASSWORD", ""),
        author_name: ENV.fetch("TEMPLATE_GIT_AUTHOR_NAME", "Decidim Community Templates"),
        author_email: ENV.fetch("TEMPLATE_GIT_AUTHOR_EMAIL", "decidim-community-templates@example.org")
      }
    end
  end
end
