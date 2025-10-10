# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplateModalCell < Decidim::ViewModel
        include Decidim::CommunityTemplates::Admin::ApplicationHelper

        def show
          render
        end

        private

        def current_organization
          space.organization
        end

        def modal_title
          raise NotImplementedError
        end

        def public_url
          raise NotImplementedError
        end

        def open?
          false
        end

        def modal_id
          "modal-template-#{space.id}"
        end

        def modal_modifier
          raise NotImplementedError
        end

        def form_method
          "POST"
        end

        def modal_form_for(&)
          raise NotImplementedError
        end

        def i18n_form_scope
          "decidim.community_templates.admin.template_form"
        end

        def i18n_scope
          raise NotImplementedError
        end

        def space_gid
          @space_gid ||= space.to_global_id.to_s
        end

        def space
          raise NotImplementedError
        end

        def template
          raise NotImplementedError
        end

        def links_csv
          return "" if template.links.blank?

          template.links.join(", ")
        end

        def form
          @form ||= Decidim::CommunityTemplates::Admin::TemplateSourceForm.new(
            template:,
            source_id: space_gid
          )
        end

        # Return admin routes for community templates engine
        def decidim_admin_community_templates
          @decidim_admin_community_templates ||= Decidim::CommunityTemplates::AdminEngine.routes.url_helpers
        end
      end
    end
  end
end
