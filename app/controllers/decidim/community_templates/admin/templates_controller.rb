# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplatesController < Decidim::CommunityTemplates::Admin::ApplicationController
        layout "decidim/community_templates/admin/templates"

        helper Decidim::CardHelper
        helper_method :tab, :tab_path, :templates

        before_action do
          enforce_permission_to :read, :admin_dashboard
        end

        # shows the list of participatory spaces to create a new template from
        def index
          @form = form(TemplateForm).instance
        end

        # shows template lists for external or local templates
        def show; end

        # shows the form to create a new template from a participatory space
        def new
          @form = form(TemplateForm).from_params(params)

          return redirect_to templates_path, alert: t(".participatory_space_not_found") if @form.participatory_space.blank? || @form.serializer.blank?
          return redirect_to templates_path, alert: t(".serializer_not_found") if @form.serializer.blank?
        end

        def download
          zipfile = Decidim::CommunityTemplates::Zipper.new(path: template_full_path)
          zipfile.zip!
          send_file zipfile.zipfile.path, filename: "#{template_id}.zip", type: "application/zip"
        rescue StandardError
          redirect_back fallback_location: template_path(tab), alert: I18n.t("decidim.community_templates.admin.templates.download.error")
        ensure
          zipfile&.zipfile&.close
        end

        def create
          @form = form(TemplateForm).from_params(params)

          CreateTemplate.call(@form) do
            on(:ok) do
              redirect_to template_path(:local), notice: I18n.t("decidim.community_templates.admin.templates.create.success")
            end

            on(:invalid) do |errors|
              flash.now[:alert] = I18n.t("decidim.community_templates.admin.templates.create.error", errors:)
              render :new
            end
          end
        end

        private

        def template_full_path
          @template_full_path ||= File.join(Decidim::CommunityTemplates.local_path, params[:id].to_s)
        end

        def template_id
          @template_id ||= params[:id].to_s.split("/").last
        end

        def tab
          params[:id] == "local" ? :local : :external
        end

        def tab_path
          tab == :local ? tab : "#{tab}/*"
        end

        def templates
          locales = ([I18n.locale.to_s, current_organization.default_locale.to_s] + current_organization.available_locales.map(&:to_s)).uniq

          Dir.glob("#{Decidim::CommunityTemplates.local_path}/#{tab_path}/*/data.json").map do |template_file|
            TemplateParser.new(File.dirname(template_file), locales)
          end
        end
      end
    end
  end
end
