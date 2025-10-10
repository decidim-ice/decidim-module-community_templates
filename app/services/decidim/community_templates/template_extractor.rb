# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    ##
    # Extract a template from a directory <catalog_path>/<id>
    #
    class TemplateExtractor
      include ActiveModel::Model
      include Decidim::AttributeObject::Model
      attribute :template_path, String
      attribute :locales, Array[String]
      validates :template_path, presence: true
      validates :locales, inclusion: { in: Decidim.available_locales.map(&:to_s) }
      validate :validate_template_path
      validate :validate_data

      def translations_path
        return nil unless dir_exists?(template_path)

        @translations_path ||= File.join(template_path, "locales")
      end

      def self.init(**args)
        extractor = new(**args)
        extractor.validate!
        extractor
      end

      def i18n_scope
        @i18n_scope ||= "decidim.community_templates.admin.template_create.errors"
      end

      def data
        @data ||= JSON.parse(read_file("data.json"))
      rescue JSON::ParserError
        errors.add(:base, I18n.t("unknown", scope: i18n_scope))
        {}
      end

      def translations
        return {} unless dir_exists?(translations_path)

        @translations ||= if dir_exists?(translations_path)
                            locales.each_with_object({}) do |lang, hash|
                              content = read_yml("locales/#{lang}.yml")
                              hash[lang] = content[lang] || {}
                            end
                          else
                            {}
                          end
      end

      def self.extract(template_path, locales = Decidim.available_locales.map(&:to_s))
        extractor = init(template_path: template_path, locales: locales)
        extractor.parser_attributes
      end

      def parser_attributes
        @parser_attributes ||= {
          data: data,
          translations: translations,
          locales: locales
        }
      end

      def parser
        @parser ||= TemplateParser.new(**parser_attributes)
      end

      def self.parse(template_path, locales = Decidim.available_locales.map(&:to_s))
        init(template_path: template_path, locales: locales).parser
      end

      def dir_exists?(path)
        return false if path.blank?

        Dir.exist?(path)
      end

      def read_file(path)
        content = File.read(File.join(template_path, path))
        raise "Empty file" if content.blank?

        content
      rescue StandardError => e
        case e
        when Errno::ENOENT
          errors.add(:base, I18n.t("file_not_found", scope: i18n_scope))
        when Errno::ENOSPC
          errors.add(:base, I18n.t("no_space", scope: i18n_scope))
        when Errno::EACCES
          errors.add(:base, I18n.t("permission_denied", scope: i18n_scope))
        when Errno::ENAMETOOLONG
          errors.add(:base, I18n.t("name_too_long", scope: i18n_scope))
        when Errno::EROFS
          errors.add(:base, I18n.t("read_only_filesystem", scope: i18n_scope))
        else
          errors.add(:base, I18n.t("unknown", scope: i18n_scope))
        end
        "{}"
      end

      def read_yml(path)
        return {} unless File.exist?(File.join(template_path, path))

        YAML.load_file(File.join(template_path, path))
      end

      private

      def validate_template_path
        return if dir_exists?(template_path)

        errors.add(:base, I18n.t("template_path_not_found", scope: i18n_scope))
      end

      def validate_data
        return errors.add(:base, I18n.t("data_blank", scope: i18n_scope)) if data.blank? || data.empty?

        metas = TemplateMetadata.new(data)
        metas.validate
        metas.errors.full_messages.each do |message|
          errors.add(:base, I18n.t("malformed_data", scope: i18n_scope, error_message: message))
        end
      end
    end
  end
end
