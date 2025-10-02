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
            weight: model.weight
          }
        end

        def settings
          [:global, :step].index_with do |scope|
            model.manifest.settings(scope).attributes.map do |type, value|
              {
                type: type.to_s,
                value: value.translated? ? i18n_field(type, model.settings[type], "settings") : model.settings[type]
              }
            end
          end
        end
      end
    end
  end
end
