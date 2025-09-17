# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    # This is the engine that runs on the public interface of decidim-community_templates.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::CommunityTemplates

      initializer "decidim-community_templates.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "decidim-community_templates.catalog_adapters" do |_app|
        Decidim::CommunityTemplates.catalog_sources.each do |key, config|
          Decidim::CommunityTemplates.catalog_registry.register(key) do |manifest|
            manifest.adapter = config[:adapter]
            manifest.options = config[:options] || {}
          end
        end
      end
    end
  end
end
