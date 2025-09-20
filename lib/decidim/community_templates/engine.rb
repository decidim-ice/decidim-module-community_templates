# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    # This is the engine that runs on the public interface of decidim-community_templates.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::CommunityTemplates

      initializer "decidim-community_templates.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "decidim-community_templates.git_mirror" do
        if Decidim::CommunityTemplates.git_settings[:url].present?
          mirror = Decidim::CommunityTemplates::GitMirror.instance
          mirror.configure(
            repo_url: Decidim::CommunityTemplates.git_settings[:url],
            repo_branch: Decidim::CommunityTemplates.git_settings[:branch],
            repo_username: Decidim::CommunityTemplates.git_settings[:username],
            repo_password: Decidim::CommunityTemplates.git_settings[:password],
            repo_author_name: Decidim::CommunityTemplates.git_settings[:author_name],
            repo_author_email: Decidim::CommunityTemplates.git_settings[:author_email]
          )
          mirror.validate!
        end
      end

      initializer "decidim-community_templates.catalog_adapters" do |_app|
        Decidim::CommunityTemplates.catalog_sources.each do |key, config|
          Decidim::CommunityTemplates.catalog_registry.register(key) do |manifest|
            manifest.adapter = config[:adapter]
            manifest.options = config[:options] || {}
          end
        end
      end

      initializer "decidim-community_templates.serializers" do |_app|
        Decidim::CommunityTemplates.serializers.each do |config|
          Decidim::CommunityTemplates.serializer_registry.register(config[:model]) do |manifest|
            manifest.serializer = config[:serializer]
            manifest.model = config[:model]
            manifest.options = config[:options] || {}
          end
        end
      end
    end
  end
end
