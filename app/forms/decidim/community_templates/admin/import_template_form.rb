# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class ImportTemplateForm < Decidim::Form
        attribute :id, String
        attribute :demo, Boolean, default: false

        def template_path
          @template_path ||= "#{Decidim::CommunityTemplates.catalog_path}/#{id}"
        end

        def locales
          @locales ||= ([context.current_organization.default_locale.to_s] + context.current_organization.available_locales.map(&:to_s)).uniq
        end

        def parser
          @parser ||= TemplateExtractor.parse(template_path, locales)
        end
      end
    end
  end
end
