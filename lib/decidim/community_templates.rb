# frozen_string_literal: true

require "decidim/community_templates/admin"
require "decidim/community_templates/admin_engine"
require "decidim/community_templates/engine"

module Decidim
  # This namespace holds the logic of the `decidim-community_templates` module.
  module CommunityTemplates
    include ActiveSupport::Configurable

    # Path where local templates are stored.
    # If this folder doesn't exist, it will be created automatically.
    # Note that you might want to ensure persistence of this folder if you're using
    # a containerized deployment (e.g. use a volume in Docker).
    attribute_accessor :local_templates_path do
      Rails.public_path.join("community_templates")
    end

    # Path where the module's built-in templates are stored.
    attribute_accessor :templates_path do
      Decidim::CommunityTemplates::Engine.root.join("templates")
    end
  end
end
