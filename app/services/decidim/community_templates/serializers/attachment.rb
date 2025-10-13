# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class Attachment < SerializerBase
        def attributes
          {
            content_type: model.content_type,
            name: model.name,
            record_type: model.record_type,
            filename: filename,
            extension: model.blob.filename.extension
          }
        end

        def assets!
          @assets << self
        end

        def blob
          @blob ||= model.blob
        end

        def filename
          @filename ||= self.class.filename(model)
        end

        def self.filename(blob_or_model)
          blob = blob_or_model
          blob = blob_or_model.blob unless blob_or_model.is_a?(ActiveStorage::Blob)
          base64_checksum = Base64.urlsafe_encode64(blob.checksum.to_s)
          "#{base64_checksum.parameterize}_#{blob_or_model.created_at.strftime("%Y%m%d%H%M%S")}.#{blob.filename.extension}"
        end
      end
    end
  end
end
