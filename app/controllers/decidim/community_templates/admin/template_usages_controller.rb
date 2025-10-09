# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplateUsagesController < Decidim::CommunityTemplates::Admin::ApplicationController
        def create
          Decidim::CommunityTemplates::TemplateMetadata.find(template_id)
          form = ImportTemplateForm.new(id: template_id).with_context(current_organization:, current_user:)
          ImportTemplate.call(form) do
            on(:ok) do |object|
              flash[:notice] = I18n.t("decidim.community_templates.admin.template_usages.create.success")
              redirect_to ResourceLocatorPresenter.new(object).edit
            end

            on(:invalid) do |_error_message|
              flash[:alert] = I18n.t("decidim.community_templates.admin.template_usages.create.error")
              redirect_back fallback_location: decidim_admin.root_path
            end
          end
        end

        private

        def template_id
          params.require(:template_id)
        end
      end
    end
  end
end
