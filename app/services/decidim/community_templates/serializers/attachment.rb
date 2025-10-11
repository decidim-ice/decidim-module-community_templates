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

        def self.filename(model)
          base64_checksum = Base64.urlsafe_encode64(model.blob.checksum.to_s)
          base64_checksum.parameterize
        end
      end
    end
  end
end
