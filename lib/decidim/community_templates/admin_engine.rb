# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::CommunityTemplates::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :templates

        root to: "templates#index"
      end

      initializer "decidim_community_templates.admin_mount_routes" do
        Decidim::Core::Engine.routes do
          mount Decidim::CommunityTemplates::AdminEngine, at: "/admin/community_templates", as: "decidim_admin_community_templates"
        end
      end

      initializer "decidim_community_templates.register_icons" do |_app|
        Decidim.icons.register(name: "apps-line", icon: "apps-line", category: "system", description: "Community Templates", engine: :admin)
      end

      initializer "decidim_community_templates.admin_menu" do
        Decidim.menu :admin_menu do |menu|
          menu.add_item(
            :community_templates,
            I18n.t("menu.community_templates", scope: "decidim.community_templates.admin"),
            decidim_admin_community_templates.templates_path,
            icon_name: "apps-line",
            position: 7.2,
            active: :inclusive,
            if: allowed_to?(:update, :organization, organization: current_organization)
          )
        end
      end
    end
  end
end
