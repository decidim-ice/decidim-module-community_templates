# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    # This is the engine that runs on the public interface of decidim-community_templates.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::CommunityTemplates

      initializer "decidim-community_templates.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
