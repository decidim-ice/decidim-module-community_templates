# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class TemplateParser
      def initialize(template_path, locales = Decidim.available_locales.map(&:to_s))
        @template_path = template_path
        @translations_path = File.join(@template_path, "locales")
        @locales = locales
      end

      attr_reader :template_path, :translations_path, :locales

      def id
        @id ||= metadata["id"] || File.basename(@template_path)
      end

      def name
        translation_for(metadata["name"])
      end

      def description
        translation_for(metadata["description"])
      end

      def version
        metadata["version"]
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

      def metadata
        data.except("attributes")
      end

      def attributes
        data["attributes"] || {}
      end

      def method_missing(method, *args, &)
        if method.to_s.start_with?("model_")
          key = method.to_s.sub("model_", "")
          return translation_for(attributes[key]) if attributes.has_key?(key)
        end
        super
      end

      def respond_to_missing?(method, include_private = false)
        if method.to_s.start_with?("model_")
          key = method.to_s.sub("model_", "")
          return true if attributes.has_key?(key)
        end
        super
      end

      def data
        @data ||= JSON.parse(File.read(File.join(@template_path, "data.json")))
      end

      def demo
        @demo ||= if File.exist?(File.join(@template_path, "demo.json"))
                    JSON.parse(File.read(File.join(@template_path, "demo.json")))
                  else
                    {}
                  end
      end

      def translation_for(field)
        return unless field

        find_translation(field) || metadata[field]
      rescue StandardError
        metadata[field]
      end

      private

      def find_translation(field)
        locales.each do |locale|
          value = translations.dig(locale, *field.split("."))
          return value if value
        end
        nil
      end
    end
  end
end
