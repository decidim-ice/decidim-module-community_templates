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

        def modal_id
          "template-create-#{space.id}"
        end

        def modal_form_for(&block)
          form_for form, url: decidim_admin_community_templates.template_sources_path, html: { :class => "form form-defaults", "data-remote" => true }, method: :post do |f|
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
