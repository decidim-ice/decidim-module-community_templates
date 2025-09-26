# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class TemplateExtractor
      def initialize(template_path, locales)
        @template_path = template_path
        @locales = locales
        @translations_path = File.join(@template_path, "locales")
      end
      attr_reader :template_path, :translations_path, :locales

      def data
        @data ||= JSON.parse(File.read(File.join(@template_path, "data.json")))
      end

      def translations
        @translations ||= if Dir.exist?(@translations_path)
                            locales.each_with_object({}) do |lang, hash|
                              file = File.join(@translations_path, "#{lang}.yml")
                              next unless File.exist?(file)

                              hash[lang] = YAML.load_file(file)[lang] || {}
                            end
                          else
                            {}
                          end
      end

      def self.extract(template_path, locales = Decidim.available_locales.map(&:to_s))
        template = new(template_path, locales)
        {
          data: template.data,
          translations: template.translations,
          locales: locales
        }
      end

      def self.parse(template_path, locales = Decidim.available_locales.map(&:to_s))
        TemplateParser.new(**extract(template_path, locales))
      end

      def self.collection_from(glob_path, locales = Decidim.available_locales.map(&:to_s))
        Dir.glob("#{glob_path}/*/data.json").map do |template_file|
          path = File.dirname(template_file)
          {
            path:,
            parser: parse(path, locales)
          }
        end
      end
    end
  end
end
