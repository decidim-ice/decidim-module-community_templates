# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class Attachment < ImporterBase
        def import!
          # Create an active storage attachment from filename, and check attributes match from data.
          filename = required!(:@local_path, parser.attributes["@local_path"])
          raise "File does not exists: #{filename}" unless File.exist?(filename)

          ActiveStorage::Attachment.create!(
            blob: ActiveStorage::Blob.create_and_upload!(
              io: File.open(filename),
              filename: "#{filename}.#{parser.attributes["extension"]}"
            ),
            record: parent.object,
            name: parser.attributes["name"]
          )
        end
      end
    end
  end
end
