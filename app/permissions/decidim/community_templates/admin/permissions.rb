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

          permission_action
        end

        private

        def read_admin_dashboard_action?
          permission_action.action == :read &&
            permission_action.subject == :admin_dashboard
        end
      end
    end
  end
end
