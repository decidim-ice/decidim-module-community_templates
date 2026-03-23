# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class Post < SerializerBase
        def attributes
          {
            title: i18n_field(:title),
            body: i18n_field(:body),
            created_at_relative: to_relative_date(model.created_at),
            updated_at_relative: to_relative_date(model.updated_at),
            published_at_relative: to_relative_date(model.published_at),
            deleted_at_relative: to_relative_date(model.deleted_at),
            decidim_author_type: author_serialized_type,
            attachments: attachments
          }
        end

        def attachments
          model.attachments.map do |attachment|
            next nil unless attachment.file.attached?

            attachment_id = SerializerBase.id_for_model(attachment)
            attachment_data = {
              title: i18n_field(:title, attachment.title, "attributes.attachments.#{attachment_id}"),
              description: i18n_field(:description, attachment.description, "attributes.attachments.#{attachment_id}"),
              content_type: attachment.content_type,
              file_size: attachment.file_size,
              weight: attachment.weight,
              file: reference_asset(attachment.file.attachment)
            }
            attachment_data
          end.compact
        end


        private

        def author_serialized_type
          if author_is_organization?
            "organization"
          else
            nil
          end
        end

        def author_is_organization?
          model.decidim_author_type == "Decidim::Organization"
        end
      end
    end
  end
end

