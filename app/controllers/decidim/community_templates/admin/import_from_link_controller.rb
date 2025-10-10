# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class ImportFromLinkController < ApplicationController
        def create
          raise InvalidRequestError unless request.xhr?

          if install?
            import_template
          else
            fetch_template
          end
        end

        def fetch_template
          @form = DirectLinkForm.from_params(params)
          @form.validate
          render partial: "direct_link_modal_form", locals: { form: @form }
        end

        def import_template
          @form = DirectLinkForm.from_params(params).with_context(current_organization:, current_user:)
          ImportTemplate.call(@form) do |_on|
            on(:ok) do |object|
              object_url = ResourceLocatorPresenter.new(object).edit
              flash.now[:notice] = I18n.t("decidim.community_templates.admin.import_from_link.success")
              render partial: "direct_link_modal_success", locals: { form: @form, redirect_url: object_url }
            end
            on(:invalid) do |_error_message|
              render partial: "direct_link_modal_form", locals: { form: @form }
            end
          end
        end

        def install?
          params[:commit] == "install"
        end
      end
    end
  end
end
