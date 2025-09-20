# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::CommunityTemplates::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :templates do
          collection do
            get "download/:id", to: "templates#download", as: :download
          end
        end

        resources :catalogs

        root to: "templates#show", id: :external
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
          menu.add_item :community_templates,
                        I18n.t("menu.community_templates", scope: "decidim.community_templates.admin"),
                        decidim_admin_community_templates.template_path(:external),
                        icon_name: "apps-line",
                        position: 7.2,
                        active: :inclusive,
                        if: allowed_to?(:update, :organization, organization: current_organization)
        end

        Decidim.menu :community_templates_admin_templates_menu do |menu|
          menu.add_item :create,
                        I18n.t("menu.create_template", scope: "decidim.community_templates.admin"),
                        decidim_admin_community_templates.templates_path,
                        position: 1,
                        icon_name: "add-line",
                        active: :exact

          menu.add_item :external,
                        I18n.t("menu.external_templates", scope: "decidim.community_templates.admin"),
                        decidim_admin_community_templates.template_path(:external),
                        position: 2,
                        icon_name: "download-cloud-2-line",
                        active: is_active_link?(decidim_admin_community_templates.template_path(:external))

          menu.add_item :local,
                        I18n.t("menu.local_templates", scope: "decidim.community_templates.admin"),
                        decidim_admin_community_templates.template_path(:local),
                        position: 3,
                        icon_name: "upload-cloud-2-line",
                        active: is_active_link?(decidim_admin_community_templates.template_path(:local))
          menu.add_item :catalogs,
                        I18n.t("menu.manage_catalogs", scope: "decidim.community_templates.admin"),
                        decidim_admin_community_templates.catalogs_path,
                        position: 4,
                        icon_name: "archive-line",
                        active: is_active_link?(decidim_admin_community_templates.catalogs_path)
        end
      end
    end
  end
end
