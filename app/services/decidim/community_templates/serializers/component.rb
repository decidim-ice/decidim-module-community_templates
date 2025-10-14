# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class Component < SerializerBase
        def attributes
          {
            manifest_name: model.manifest_name,
            name: i18n_field(:name),
            global_settings: global_settings,
            step_settings: step_settings,
            default_step_settings: default_step_settings,
            weight: model.weight,
            published_at: model.published_at&.iso8601
          }
        end

        def global_settings
          model.manifest.settings(:global).attributes.map do |type, value|
            {
              type: type.to_s,
              value: setting_value(model.settings[type], key: type, manifest: value, scope: "global")
            }
          end
        end

        def default_step_settings
          model.manifest.settings(:default_step).attributes.map do |type, value|
            {
              type: type.to_s,
              value: setting_value(model.default_step_settings[type], key: type, manifest: value, scope: "default_step")
            }
          end
        end

        def step_settings
          step = model.step_settings
          step.map do |step_key, step_value|
            [
              step_key, 
              model.manifest.settings(:step).attributes.map do |type, value|
                {
                  type: type.to_s,
                  value: setting_value(step_value[type], key: step_key, manifest: value, scope: "scope.#{step_key}")
                }
              end
            ]
          end.to_h
        end



        def setting_value(setting_value, key:, manifest:, scope:)
          setting_value = i18n_field(key, setting_value, "#{scope}.settings") if manifest.translated?
          setting_value = !!setting_value if manifest.type == :boolean
          setting_value
        end
      end
    end
  end
end
