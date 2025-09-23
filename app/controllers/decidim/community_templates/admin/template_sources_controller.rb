# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplateSourcesController < Decidim::CommunityTemplates::Admin::ApplicationController
        attr_reader :form

        def create
          enforce_permission_to :templatize, :space, space: source_record
          @form = Decidim::CommunityTemplates::Admin::TemplateSourceForm.new(
            source_id: source_guid,
            template: template_params
          )
          form.template.id = SecureRandom.uuid
          update_template_values!(form.template)
          Decidim::CommunityTemplates::Admin::CreateCommunityTemplateCommand.call(form, current_organization) do
            on(:ok) do
              redirect_back fallback_location: decidim_admin.root_path, notice: t(".success")
            end
            on(:invalid) do
              if request.xhr?
                @template_source = nil
                render partial: "modal", locals: { source_record: source_record }
              else
                redirect_back fallback_location: decidim_admin.root_path, error: t(".error")
              end
            end
          end
        end

        def update
          enforce_permission_to :templatize, :space, space: source_record

          @template_source = match = Decidim::CommunityTemplates::TemplateSource.find_by(template_id: params.require(:id))
          raise ActionController::RoutingError, "Not Found" unless match

          @form = Decidim::CommunityTemplates::Admin::TemplateSourceForm.new(
            source_id: match.source.to_global_id,
            template: template_params
          )
          form.template.id = match.template_id
          update_template_values!(form.template)

          Decidim::CommunityTemplates::Admin::UpdateCommunityTemplateCommand.call(form) do
            on(:ok) do
              redirect_back fallback_location: decidim_admin.root_path, notice: t(".success")
            end
            on(:invalid) do
              if request.xhr?
                render partial: "modal"
              else
                redirect_back fallback_location: decidim_admin.root_path, error: t(".error")
              end
            end
          end
        end

        private

        def update_template_values!(template)
          template.default_locale = I18n.default_locale.to_s
          template.source_type = source_record.class.name
          template.community_template_version = Decidim::CommunityTemplates::VERSION
          template.decidim_version = Decidim.version
        end

        def source_record
          @source_record ||= GlobalID::Locator.locate(source_guid)
        end

        def source_guid
          @source_guid ||= params.require(:template_source).require(:source_id)
        end

        def template_params
          @template_params ||= params.require(:template_source).require(:template).permit(
            :title,
            :author,
            :links,
            :version,
            :short_description
          )
        end
      end
    end
  end
end
