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
            settings:,
            weight: parser.model_weight
          }.compact
          @object = Decidim::Component.create!(component_attributes)
        end

        def settings
          return nil unless parser.model_settings(locales).is_a?(Hash)

          parser.attributes["settings"].dup.transform_values do |scoped_settings|
            scoped_settings.each do |setting|
              setting["value"] = parser.all_translations_for(setting["value"], locales) if setting["value"].is_a?(String) && setting["value"].start_with?("#{parser.id}.settings.")
            end
          end
        end
      end
    end
  end
end
