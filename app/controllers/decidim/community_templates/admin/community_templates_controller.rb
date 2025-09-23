# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class CommunityTemplatesController < ApplicationController
        layout "decidim/community_templates/admin/community_templates"
        add_breadcrumb_item_from_menu :admin_participatory_processes_menu

        helper_method :catalog
        def index
          enforce_permission_to :read, :catalog
        end

        private

        def catalog
          Decidim::CommunityTemplates::Catalog.from_path(Decidim::CommunityTemplates.catalog_path)
        end
      end
    end
  end
end
