# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class Attachment < ImporterBase
        def import!
          validate_parent!
          # Create an active storage attachment from filename, and check attributes match from data.
          filename = required!(:@local_path, parser.attributes["@local_path"])
          raise "File does not exists: #{filename}" unless File.exist?(filename)

          # Attach and save.
          # see https://github.com/rails/rails/issues/43663 to understand why we need to save
          blob = ActiveStorage::Blob.create_and_upload!(
            io: File.open(filename),
            filename: "#{parser.model_filename}.#{parser.model_extension}",
            identify: false,
            content_type: parser.model_content_type
          )
          parent.object.attach(
            blob
          )
          parent.object.save if parent.object.respond_to?(:save)
          parent.object.attachment.save if parent.object.respond_to?(:attachments)
          @object = parent.object.blob
        end

        private

        def validate_parent!
          raise "parent.object is nil" if parent.object.nil?
          raise "parent.object do not respond to attach, Did you sent a ActiveStorage::Attached::One or ActiveStorage::Attached::Many?" unless parent.object.respond_to?(:attach)
          unless parent.object.respond_to?(:attached?)
            raise "parent.object do not respond to attached? Did you sent a ActiveStorage::Attached::One or ActiveStorage::Attached::Many?"
          end
        end
      end
    end
  end
end
