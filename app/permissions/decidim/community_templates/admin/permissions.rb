# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          return permission_action unless user
          return permission_action unless permission_action.scope == :admin

          unless user.admin?
            disallow!
            return permission_action
          end

          if read_admin_dashboard_action?
            allow!
            return permission_action
          end

          if templatize_action?
            allow!
            return permission_action
          end

          if read_catalog_action?
            allow!
            return permission_action
          end

          permission_action
        end

        private

        def read_admin_dashboard_action?
          permission_action.action == :read &&
            permission_action.subject == :admin_dashboard
        end

        def templatize_action?
          permission_action.action == :templatize &&
            permission_action.subject == :space
        end

        def read_catalog_action?
          permission_action.action == :read &&
            permission_action.subject == :catalog
        end
      end
    end
  end
end
