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
            start_date_relative: to_relative_date(model.start_date),
            end_date_relative: to_relative_date(model.end_date),
            developer_group: i18n_field(:developer_group),
            local_area: i18n_field(:local_area),
            meta_scope: i18n_field(:meta_scope),
            target: i18n_field(:target),
            participatory_scope: i18n_field(:participatory_scope),
            participatory_structure: i18n_field(:participatory_structure),
            private_space: model.private_space,
            promoted: model.promoted,
            components:,
            hero_image:,
            content_blocks:,
            steps:
          }
        end

        def hero_image
          return nil if model.hero_image&.attachment.blank?

          attachment = model.hero_image.attachment
          reference_asset(attachment)
        end

        def components
          model.components.map do |component|
            append_serializer(Serializers::Component, component, "components.#{component.manifest_name}_#{SerializerBase.id_for_model(component)}")
          end
        end

        def content_blocks
          content_blocks = Decidim::ContentBlock.for_scope("participatory_process_homepage", organization: model.organization).unscoped.where(
            scoped_resource_id: model.id
          )
          content_blocks.map do |content_block|
            append_serializer(Serializers::ContentBlock, content_block, "content_blocks.#{content_block.scope_name}_#{SerializerBase.id_for_model(content_block)}")
          end
        end

        def steps
          model.steps.map do |step|
            append_serializer(Serializers::ProcessStep, step, "steps.#{SerializerBase.id_for_model(step)}")
          end
        end
      end
    end
  end
end
