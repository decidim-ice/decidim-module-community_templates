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
            published_at: from_relative_date(parser.model_published_at)
          }.compact
          @object = Decidim::Component.create!(component_attributes)
          @object.settings = global_settings
          @object.step_settings = step_settings
          @object.default_step_settings = default_step_settings

          @object.save!
          @object.reload
        end

        def default_step_settings
          (parser.attributes["default_step_settings"] || []).to_h do |key_value|
            key_value_to_hash(key_value)
          end
        end

        def global_settings
          (parser.attributes["global_settings"] || []).to_h do |key_value|
            key_value_to_hash(key_value)
          end
        end

        def step_settings
          settings = parser.attributes["step_settings"] || {}
          settings.to_h do |step_key, step_settings|
            step = parent_steps[step_key]
            next [] unless step

            [
              step.id,
              step_settings.map do |key_value|
                key_value_to_hash(key_value)
              end
            ]
          end
        end

        def key_value_to_hash(key_value)
          key = key_value["type"]
          value = key_value["value"]
          value = parser.all_translations_for(value, locales) if value.is_a?(String) && value.start_with?("#{parser.id}.") && value.end_with?("_settings.#{key}")
          [key, value]
        end

        def parent_steps
          @parent_steps ||= parent.created_steps
        end
      end
    end
  end
end
