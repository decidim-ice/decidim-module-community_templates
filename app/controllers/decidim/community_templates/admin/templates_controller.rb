# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplatesController < Decidim::CommunityTemplates::Admin::ApplicationController
        layout "decidim/community_templates/admin/templates"

        helper_method :tab, :tab_path, :templates

        before_action do
          enforce_permission_to :read, :admin_dashboard
        end

        def index
          @template_form = form(TemplateForm).instance
        end

        def show; end

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
          @template_form = form(TemplateForm).from_params(params)

          CreateTemplate.call(@template_form) do
            on(:ok) do
              redirect_to template_path(:local), notice: I18n.t("decidim.community_templates.admin.templates.create.success")
            end

            on(:invalid) do |errors|
              flash.now[:alert] = I18n.t("decidim.community_templates.admin.templates.create.error", errors:)
              render :index
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
          Dir.glob("#{Decidim::CommunityTemplates.local_path}/#{tab_path}/*/data.json").map do |template_file|
            JSON.parse(File.read(template_file)).merge("id" => File.basename(File.dirname(template_file)))
          end
        end
      end
    end
  end
end
