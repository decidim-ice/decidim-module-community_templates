# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class Component < SerializerBase
        def attributes
          {
            manifest_name: model.manifest_name,
            name: i18n_field(:name),
            settings:,
            weight: model.weight,
            permissions: model.permissions,
            visible: model.visible
          }
        end

        def settings
          [:global, :step].flat_map do |scope|
            model.manifest.settings(scope).attributes.map do |type, value|
              {
                type: type.to_s,
                value: value.translated? ? i18n_setting_field(type) : model.settings[type]
              }
            end
          end
        end
      end
    end
  end
end
