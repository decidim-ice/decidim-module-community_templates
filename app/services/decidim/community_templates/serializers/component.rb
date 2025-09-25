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
            published_at: model.published_at&.iso8601,
            created_at: model.created_at.iso8601,
            updated_at: model.updated_at.iso8601,
            visible: model.visible,
            deleted_at: model.deleted_at&.iso8601
          }
        end

        def settings
          model.manifest.settings.attributes.map do |type, value|
            {
              type:,
              value:
            }
          end
        end
      end
    end
  end
end
