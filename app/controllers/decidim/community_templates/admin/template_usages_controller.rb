# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplateUsagesController < Decidim::CommunityTemplates::Admin::ApplicationController
        def create
          Decidim::CommunityTemplates::TemplateMetadata.find(template_id)
          raise "Not Implemented"
        end

        private

        def template_id
          params.require(:template_id)
        end
      end
    end
  end
end
