# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class ParticipatoryProcess < SerializerBase
        def attributes
          {
            title: i18n_field(:title),
            description: i18n_field(:description),
            components:
          }
        end

        def components
          model.components.map do |component|
            append_serializer(Serializers::Component, component, "components.#{component.id}")
          end
        end
      end
    end
  end
end
