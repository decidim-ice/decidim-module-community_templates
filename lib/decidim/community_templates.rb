# frozen_string_literal: true

require "git"
require "decidim/community_templates/admin"
require "decidim/community_templates/admin_engine"
require "decidim/community_templates/engine"

module Decidim
  # This namespace holds the logic of the `decidim-community_templates` module.
  module CommunityTemplates
    include ActiveSupport::Configurable

    autoload :CatalogManifest, "decidim/community_templates/catalog_manifest"
    autoload :SerializerManifest, "decidim/community_templates/serializer_manifest"
    autoload :GitMirror, "decidim/community_templates/git_mirror"
    autoload :GitSettings, "decidim/community_templates/git_settings"
    autoload :GitError, "decidim/community_templates/error"
    autoload :GitCatalogNormalizer, "decidim/community_templates/git_catalog_normalizer"

    config_accessor :git_settings do
      {
        url: ENV.fetch("TEMPLATE_GIT_URL", ""),
        branch: ENV.fetch("TEMPLATE_GIT_BRANCH", "main"),
        username: ENV.fetch("TEMPLATE_GIT_USERNAME", ""),
        password: ENV.fetch("TEMPLATE_GIT_PASSWORD", ""),
        author_name: ENV.fetch("TEMPLATE_GIT_AUTHOR_NAME", "Decidim Community Templates"),
        author_email: ENV.fetch("TEMPLATE_GIT_AUTHOR_EMAIL", "decidim-community-templates@example.org")
      }
    end

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

    config_accessor :serializers do
      [
        {
          model: "Decidim::ParticipatoryProcess",
          serializer: "Decidim::CommunityTemplates::Serializers::ParticipatoryProcess"
        }
      ]
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
        Rails.root.join(Decidim::CommunityTemplates.local_templates_path)
      end
    end

    def self.enabled?
      git_settings[:url].present?
    end

    def self.catalog_path
      Rails.root.join("catalog")
    end

    def self.catalog_registry
      @catalog_registry ||= ManifestRegistry.new("community_templates/catalogs")
    end

    def self.serializer_registry
      @serializer_registry ||= ManifestRegistry.new("community_templates/serializers")
    end
  end
end
