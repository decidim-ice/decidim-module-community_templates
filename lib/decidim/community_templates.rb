# frozen_string_literal: true

require "decidim/community_templates/admin"
require "decidim/community_templates/admin_engine"
require "decidim/community_templates/engine"

module Decidim
  # This namespace holds the logic of the `decidim-community_templates` module.
  module CommunityTemplates
    include ActiveSupport::Configurable

    autoload :CatalogManifest, "decidim/community_templates/catalog_manifest"

    # Path where the module's built-in templates are stored.
    config_accessor :catalog_sources do
      {
        default: {
          adapter: :local_filesystem,
          options: {
            path: Decidim::CommunityTemplates::Engine.root.join("catalog"),
            label: "Demo templates"
          }
        }
      }
    end

    # Path where local templates are stored.
    # If this folder doesn't exist, it will be created automatically.
    # Note that you might want to ensure persistence of this folder if you're using
    # a containerized deployment (e.g. use a volume in Docker).
    # Unless starting with "/", this path is relative to Rails.root.
    config_accessor :local_templates_path do
      "community_templates"
    end

    def self.local_path
      if Decidim::CommunityTemplates.local_templates_path.start_with?("/")
        Pathname.new(Decidim::CommunityTemplates.local_templates_path)
      else
        Rails.root
      end.join(Decidim::CommunityTemplates.local_templates_path)
    end

    def self.catalog_registry
      @catalog_registry ||= ManifestRegistry.new("community_templates/catalogs")
    end
  end
end
