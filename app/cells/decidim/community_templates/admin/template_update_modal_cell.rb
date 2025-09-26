# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplateUpdateModalCell < TemplateModalCell
        def catalog
          @catalog = Decidim::CommunityTemplates::Catalog.from_path(Decidim::CommunityTemplates.catalog_path)
        end

        def template
          @template ||= begin
            match = catalog.templates.find { |t| t.id == model.template_id }
            raise ActiveRecord::RecordNotFound, "Template ##{model.template_id} not found" if match.nil?

            match
          end
        end

        def public_url
          template.public_url(current_organization.host)
        end

        def modal_title
          template.title
        end

        def space
          options[:form].source
        end

        def i18n_scope
          "decidim.community_templates.admin.template_update"
        end

        def open?
          options[:form].present?
        end

        def modal_form_for(&block)
          modal_form = options[:form] || form
          modal_form.validate
          form_for modal_form,
                   url: decidim_admin_community_templates.template_source_path(template.id),
                   html: {
                     :class => "form form-defaults js-template-modal-form",
                     "data-source" => space.to_global_id,
                     "data-remote" => true
                   },
                   method: :put do |f|
            block.call(f)
          end
        end

        def modal_modifier
          "update"
        end
      end
    end
  end
end
