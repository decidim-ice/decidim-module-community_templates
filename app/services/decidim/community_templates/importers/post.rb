# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class Post < ImporterBase
        def import!
          # Skip import if author is not organization and not a demo
          return unless should_import?

          post_attributes = {
            title: parser.model_title(locales),
            body: parser.model_body(locales),
            component: parent.object,
            created_at: from_relative_date(parser.attributes["created_at_relative"]),
            updated_at: from_relative_date(parser.attributes["updated_at_relative"]),
            published_at: from_relative_date(parser.attributes["published_at_relative"]),
            deleted_at: from_relative_date(parser.attributes["deleted_at_relative"])
          }

          author_id, author_type = author_for_import
          post_attributes[:decidim_author_id] = author_id
          post_attributes[:decidim_author_type] = author_type

          @object = Decidim::Blogs::Post.create!(post_attributes)
        end

        def after_import!
          return if @object.nil?

          import_attachments!
          after_import_serializers.each(&:after_import!)
          @object.save!
          @object.reload
        end

        def import_attachments!
          (parser.attributes["attachments"] || []).each do |attachment_data|
            file_asset_id = attachment_data["file"]
            asset_data = parser.assets.find { |asset| asset["id"] == file_asset_id }
            next unless asset_data

            attachment_parser = TemplateParser.new(
              data: { **asset_data, name: "file" },
              translations: parser.translations,
              locales: parser.locales,
              assets: parser.assets,
              i18n_vars: parser.i18n_vars
            )

            attachment = Decidim::Attachment.create!(
              title: parser.all_translations_for(attachment_data["title"], locales, ignore_missing: true) || {},
              description: parser.all_translations_for(attachment_data["description"], locales, ignore_missing: true) || {},
              attached_to: @object,
              content_type: attachment_data["content_type"],
              file_size: attachment_data["file_size"],
              weight: attachment_data["weight"] || 0
            )

            attachment_importer = Decidim::CommunityTemplates::Importers::Attachment.new(
              attachment_parser,
              organization,
              user,
              parent: OpenStruct.new(object: attachment.file),
              for_demo: demo?
            )
            attachment_importer.import!
            attachment.save!
          end
        end

        private

        def should_import?
          author_type = parser.attributes["decidim_author_type"]
          return true if author_type == "organization"
          return true if demo?

          false
        end

        def author_for_import
          author_type = parser.attributes["decidim_author_type"]
          if author_type == "organization"
            [organization.id, "Decidim::Organization"]
          elsif demo?
            dummy_user = dummy_users.pick_one
            [dummy_user.id, "Decidim::UserBaseEntity"]
          else
            [nil, nil]
          end
        end
      end
    end
  end
end

