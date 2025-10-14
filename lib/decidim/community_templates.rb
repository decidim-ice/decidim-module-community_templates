# frozen_string_literal: true

require "git"
require "decidim/community_templates/admin"
require "decidim/community_templates/admin_engine"
require "decidim/community_templates/engine"

module Decidim
  # This namespace holds the logic of the `decidim-community_templates` module.
  module CommunityTemplates
    include ActiveSupport::Configurable

    autoload :SerializerManifest, "decidim/community_templates/serializer_manifest"
    autoload :GitMirror, "decidim/community_templates/git_mirror"
    autoload :GitSettings, "decidim/community_templates/git_settings"
    autoload :GitError, "decidim/community_templates/error"
    autoload :GitCatalogNormalizer, "decidim/community_templates/git_catalog_normalizer"
    autoload :TemplateMetadata, "decidim/community_templates/template_metadata"
    autoload :ResetOrganization, "decidim/community_templates/reset_organization"

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
    config_accessor :demo do
      {
        host: ENV.fetch("TEMPLATE_DEMO_HOST", "demo.example.org"),
        name: ENV.fetch("TEMPLATE_DEMO_NAME", "Demo Organization"),
        primary_color: ENV.fetch("TEMPLATE_DEMO_PRIMARY_COLOR", "#14342B"),
        secondary_color: ENV.fetch("TEMPLATE_DEMO_SECONDARY_COLOR", "#006482"),
        tertiary_color: ENV.fetch("TEMPLATE_DEMO_TERTIARY_COLOR", "#F7E733")
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

    # Path where templates are stored.
    # If this folder doesn't exist, it will be created automatically.
    # Note that you might want to ensure persistence of this folder if you're using
    # a containerized deployment (e.g. use a volume in Docker).
    # Unless starting with "/", this path is relative to Rails.root.
    config_accessor :catalog_dir do
      "catalog"
    end

    def self.apartment_compat?
      @apartment_compat = Gem.loaded_specs.has_key?("decidim-apartment")
    end

    def self.demo_organization?
      if apartment_compat?
        Decidim::Apartment::DistributionKey.for_host(config.demo[:host]).present?
      else
        Decidim::Organization.find_by(host: config.demo[:host]).present?
      end
    end

    def self.with_demo_organization
      if apartment_compat?
        Decidim::Apartment::DistributionKey.for_host(config.demo[:host]).switch do
          yield Decidim::Organization.last
        end
      else
        yield Decidim::Organization.find_by(host: config.demo[:host])
      end
    end

    def self.catalog_path
      if Decidim::CommunityTemplates.catalog_dir.to_s.start_with?("/")
        Pathname.new(Decidim::CommunityTemplates.catalog_dir)
      else
        Rails.root.join(Decidim::CommunityTemplates.catalog_dir)
      end
    end

    def self.enabled?
      git_settings[:url].present?
    end

    def self.serializer_registry
      @serializer_registry ||= ManifestRegistry.new("community_templates/serializers")
    end
  end
end
