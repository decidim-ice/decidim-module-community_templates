# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class ContentBlock < SerializerBase
        def attributes
          {
            manifest_name: model.manifest_name,
            scope_name: model.scope_name,
            settings:,
            weight: model.weight,
            images_container: images_container,
            published_at_relative: to_relative_date(model.published_at)
          }
        end

        def settings
          model.manifest.settings.attributes.map do |type, value|
            {
              type: type.to_s,
              value: value.translated? ? i18n_field(type, model.settings[type], "settings") : model.settings[type]
            }
          end
        end

        def images_container
          model.images_container.manifest_attachments.transform_values do |content_block_attachment|
            reference_asset(content_block_attachment.file.attachment) unless content_block_attachment.file.attachment.nil?
          end
        end
      end
    end
  end
end
