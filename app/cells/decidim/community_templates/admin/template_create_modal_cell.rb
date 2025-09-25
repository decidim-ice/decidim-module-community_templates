# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplateCreateModalCell < TemplateModalCell
        def template
          Decidim::CommunityTemplates::Template.new
        end

        def space
          model
        end

        def form
          options[:form] || super
        end

        def i18n_scope
          "decidim.community_templates.admin.template_create"
        end

        def public_url
          nil
        end

        def modal_title
          t("title", scope: i18n_scope)
        end

        def modal_form_for(&block)
          form_for form,
                   url: decidim_admin_community_templates.template_sources_path,
                   html: {
                     :class => "form form-defaults js-template-modal-form",
                     "data-source" => space.to_global_id,
                     "data-remote" => true
                   },
                   method: :post do |f|
            block.call(f)
          end
        end

        def modal_modifier
          "create"
        end
      end
    end
  end
end
