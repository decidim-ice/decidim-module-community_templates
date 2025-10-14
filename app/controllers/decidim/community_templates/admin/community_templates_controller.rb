# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class CommunityTemplatesController < ApplicationController
        layout "decidim/community_templates/admin/community_templates"
        add_breadcrumb_item_from_menu :admin_participatory_processes_menu
        before_action :sync_catalog
        helper_method :catalog

        def index
          enforce_permission_to :read, :catalog
        end

        private

        def catalog
          Decidim::CommunityTemplates::Catalog.from_path(Decidim::CommunityTemplates.catalog_path)
        end

        def sync_catalog
          cache_key = "git_syncronizer_last_run"
          last_sync = Rails.cache.read(cache_key)

          if last_sync.nil? || last_sync < 1.minute.ago
            GitSyncronizer.call
            Rails.cache.write(cache_key, Time.current, expires_in: 1.minute)
          end
        end
      end
    end
  end
end
