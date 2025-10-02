# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class ParticipatoryProcess < SerializerBase
        def attributes
          {
            title: i18n_field(:title),
            subtitle: i18n_field(:subtitle),
            slug: model.slug,
            short_description: i18n_field(:short_description),
            description: i18n_field(:description),
            announcement: i18n_field(:announcement),
            start_date: model.start_date.iso8601,
            end_date: model.end_date.iso8601,
            developer_group: i18n_field(:developer_group),
            local_area: i18n_field(:local_area),
            meta_scope: i18n_field(:meta_scope),
            target: i18n_field(:target),
            participatory_scope: i18n_field(:participatory_scope),
            participatory_structure: i18n_field(:participatory_structure),
            private_space: model.private_space,
            promoted: model.promoted,
            components:
          }
        end

        def components
          model.components.map do |component|
            append_serializer(Serializers::Component, component, "components.#{component.manifest_name}_#{component.id}")
          end
        end
      end
    end
  end
end
