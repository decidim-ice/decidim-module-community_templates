# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class Attachment < SerializerBase
        def attributes
          raise "model or blob is nil" if model.nil? || blob.nil?

          {
            content_type: model.content_type,
            name: model.name,
            record_type: model.record_type,
            filename: filename,
            extension: self.class.guess_extension_from_content_type(blob)
          }
        end

        def assets!
          @assets << self
        end

        def blob
          @blob ||= model.is_a?(ActiveStorage::Blob) ? model : model&.blob
        end

        def filename
          @filename ||= self.class.filename(model)
        end

        def self.filename(blob_or_model)
          return nil if blob_or_model.nil?

          blob = blob_or_model
          blob = blob_or_model.blob unless blob_or_model.is_a?(ActiveStorage::Blob)
          base64_checksum = Base64.urlsafe_encode64(blob.checksum.to_s)
          "#{base64_checksum.parameterize}_#{blob_or_model.created_at.strftime("%Y%m%d%H%M%S")}#{guess_extension_from_content_type(blob)}"
        end

        def self.guess_extension_from_content_type(blob)
          return ".#{blob.filename.extension}" if blob.filename.extension.present?
          return nil if blob.content_type.nil?

          ".#{blob.content_type.split("/").last.downcase}"
        end
      end
    end
  end
end
