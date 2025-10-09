# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class DirectLinkForm < Decidim::Form
        attribute :link, String

        validates :link, presence: true

        validate :validate_manifest_file
        validate :validate_link_secure
        validate :validate_link_ends_with_uuid
        validate :validate_coherence
        validate :validate_template
        validate :validate_importer_class, if: -> { template.present? }
        delegate :name, :description, :version, :author, :links, to: :template

        alias template_id id
        def self.from_params(params)
          strong_params = params.permit(direct_link: [:link])
          new(strong_params[:direct_link])
        end

        def id
          @id ||= template&.id
        end

        def template
          @template ||= parser&.template || TemplateMetadata.new
        end

        def parser
          return nil if normalized_link.blank? || extractor.blank?

          @parser ||= TemplateParser.new(
            data: extractor.data,
            translations: extractor.translations,
            locales: Decidim.available_locales.map(&:to_s)
          )
        end

        def importer_class
          @importer_class ||= "Decidim::CommunityTemplates::Importers::#{template.attributes["@class"]&.demodulize}"
        end

        def importer
          @importer ||= importer_class.constantize if importer?
        end

        def importer?
          template && template.attributes["@class"].present? && importer_class.present? && Object.const_defined?(importer_class)
        rescue NameError
          false
        end

        def description_html
          @description_html ||= markdown_to_html(description)
        end

        def has_manifest?
          manifest_file.present?
        end

        private

        def validate_importer_class
          return if importer?

          errors.add(:importer_class, I18n.t(
                                        "importer_class_not_found",
                                        scope: "activemodel.errors.models.decidim/community_templates/template_metadata.attributes.importer_class"
                                      ))
        end

        def markdown_to_html(text)
          markdown.render(text).html_safe
        end

        def markdown
          @markdown ||= ::Decidim::Comments::Markdown.new
        end

        def normalized_link
          @normalized_link ||= (link || "").chomp("/")
        end

        def i18n_scope
          "decidim.community_templates.admin.direct_link_modal"
        end

        def manifest_file
          @manifest_file ||= extractor&.data
        end

        def folder_name
          @folder_name ||= normalized_link.split("/").last
        end

        def link_error?
          errors.has_key?(:link)
        end

        def validate_link_ends_with_uuid
          return if link.blank? || link_error?

          folder = folder_name
          return if folder.match?(Decidim::CommunityTemplates::TemplateMetadata::UUID_REGEX)

          errors.add(:link, I18n.t("errors.invalid_link", scope: i18n_scope))
        end

        def validate_link_secure
          return if link_error?

          errors.add(:link, I18n.t("errors.invalid_link", scope: i18n_scope)) unless normalized_link.start_with?("https://")
        end

        def validate_coherence
          return if link_error?

          errors.add(:link, I18n.t("errors.invalid_link", scope: i18n_scope)) unless folder_name == id
        end

        def validate_manifest_file
          errors.add(:link, I18n.t("errors.manifest_file_not_found", scope: i18n_scope)) unless has_manifest?
        end

        def validate_template
          return if errors.any?

          if template.invalid?
            template.errors.full_messages.each do |message|
              errors.add(:base, message)
            end
          end
        end

        def extractor
          return nil if normalized_link.blank?

          @extractor ||= Decidim::CommunityTemplates::HttpTemplateExtractor.init(
            template_path: normalized_link,
            locales: Decidim.available_locales.map(&:to_s)
          )
        rescue ActiveModel::ValidationError
          nil
        end
      end
    end
  end
end
