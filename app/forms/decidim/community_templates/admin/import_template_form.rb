# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class ImportTemplateForm < Decidim::Form
        attribute :id, String

        validates :id, presence: true
        validates :id, format: { with: TemplateMetadata::UUID_REGEX }
        validates :importer_class, presence: true
        validate :validate_importer_class

        def template_path
          @template_path ||= "#{Decidim::CommunityTemplates.catalog_path}/#{id}"
        end

        def locales
          @locales ||= ([current_organization.default_locale.to_s] + current_organization.available_locales.map(&:to_s)).uniq
        end

        def current_organization
          @current_organization ||= context.current_organization
        end

        def parser
          @parser ||= TemplateExtractor.parse(template_path, locales)
        rescue ActiveModel::ValidationError
          nil
        end

        def importer_class
          @importer_class ||= "Decidim::CommunityTemplates::Importers::#{parser.metadata["@class"]&.demodulize}"
        end

        def importer
          @importer ||= importer_class.constantize if importer?
        end

        def importer?
          parser && parser.metadata["@class"].present? && importer_class.present? && Object.const_defined?(importer_class)
        rescue NameError
          false
        end

        def validate_importer_class
          return if importer?

          errors.add(:importer_class, I18n.t(
                                        "importer_class_not_found",
                                        scope: "activemodel.errors.models.decidim/community_templates/template_metadata.attributes.importer_class",
                                        importer_class: importer_class
                                      ))
        end
      end
    end
  end
end
