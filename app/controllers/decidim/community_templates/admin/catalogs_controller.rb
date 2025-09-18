# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class CatalogsController < Decidim::CommunityTemplates::Admin::ApplicationController
        layout "decidim/community_templates/admin/templates"

        helper_method :catalogs_list

        before_action do
          enforce_permission_to :read, :admin_dashboard
        end

        def index; end

        # this currently does not render a view but in the future we might want to
        # let the admins choose which templates to import from the catalog
        def show
          @catalog = Decidim::CommunityTemplates.catalog_registry.find(params[:id])
          return redirect_to catalogs_path, alert: t(".not_found") unless @catalog

          @catalog.import!
          redirect_to template_path(:external), notice: t(".imported_successfully")
        end

        private

        def catalogs_list
          Decidim::CommunityTemplates.catalog_registry.manifests
        end
      end
    end
  end
end
