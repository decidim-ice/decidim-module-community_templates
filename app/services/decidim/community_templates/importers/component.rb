# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class Component < ImporterBase
        def import!
          component_attributes = {
            participatory_space: parent.object,
            name: required!(:name, parser.model_name(locales)),
            manifest_name: required!(:manifest_name, parser.model_manifest_name),
            weight: parser.model_weight,
            published_at: parser.model_published_at ? Time.zone.now : nil
          }.compact
          @object = Decidim::Component.create!(component_attributes)
          @object.settings = settings.dig("global") || {}
          @object.step_settings = settings.dig("step") || {}
          @object.default_step_settings = settings.dig("default_step") || {}
          @object.save!
          
          @object.reload
        end

        def settings
          return {} unless parser.model_settings(locales).is_a?(Hash)

          parser.attributes["settings"].dup.map do |scope, scoped_settings|
            [
              scope, 
              scoped_settings.map do |settings_hash|
                key = settings_hash["type"]
                settings = settings_hash["value"]
                settings = parser.all_translations_for(settings, locales) if settings.is_a?(String) && settings.start_with?("#{parser.id}.settings.")
                [key, settings]
              end.to_h.compact_blank
            ]
          end.to_h.compact_blank
        end
      end
    end
  end
end
