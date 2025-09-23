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
        if Decidim::CommunityTemplates.enabled?
          mirror = Decidim::CommunityTemplates::GitMirror.instance
          mirror.configure(
            repo_url: Decidim::CommunityTemplates.git_settings[:url],
            repo_branch: Decidim::CommunityTemplates.git_settings[:branch],
            repo_username: Decidim::CommunityTemplates.git_settings[:username],
            repo_password: Decidim::CommunityTemplates.git_settings[:password],
            repo_author_name: Decidim::CommunityTemplates.git_settings[:author_name],
            repo_author_email: Decidim::CommunityTemplates.git_settings[:author_email]
          )
          Decidim::CommunityTemplates::GitCatalogNormalizer.call
          mirror.validate!
        else
          warn("")
          warn("⚠ Decidim::CommunityTemplates is installed but not enabled")
          warn("================================================================")
          warn("To enable it, define your catalog with the following environment variables:")
          warn("  TEMPLATE_GIT_URL=https://github.com/your-organization/your-repo")
          warn("  TEMPLATE_GIT_BRANCH=main")
          warn("If you need to create and update your catalog, set also these variables:")
          warn("  TEMPLATE_GIT_USERNAME=your_username")
          warn("  TEMPLATE_GIT_PASSWORD=your_password")
          warn("  TEMPLATE_GIT_AUTHOR_NAME=Your Name")
          warn("  TEMPLATE_GIT_AUTHOR_EMAIL=me@example.org")
          warn("")
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

      initializer "decidim-community_templates.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::CommunityTemplates::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::CommunityTemplates::Engine.root}/app/views") # for partials
      end
    end
  end
end
