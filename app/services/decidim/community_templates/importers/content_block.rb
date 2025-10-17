# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class ContentBlock < ImporterBase
        def import!
          validate_parent!
          content_block_attributes = {
            scope_name: required!(:scope_name, parser.model_scope_name),
            scoped_resource_id: parent.object.id,
            manifest_name: required!(:manifest_name, parser.model_manifest_name),
            settings: settings,
            weight: required!(:weight, parser.model_weight).to_i,
            published_at: from_relative_date(parser.attributes["published_at_relative"])
          }.compact

          @object = Decidim::ContentBlock.create!(
            organization: parent.organization,
            **content_block_attributes
          )

          @object.save!
          @object.reload
        end

        def after_import!
          return if @object.nil?

          import_images_container!
          @object.images_container.save
          @object.reload
          after_import_serializers.each(&:after_import!)
        end

        private

        def settings
          (parser.attributes["settings"] || []).to_h { |s| key_value_to_hash(s) }.compact_blank
        end

        def key_value_to_hash(key_value)
          key = key_value["type"]
          value = key_value["value"]
          if value.is_a?(String) && value.start_with?("#{parser.id}.") && value.match?(TemplateParser::I18N_PATTERN)
            value = parser.all_translations_for(value, locales,
                                                ignore_missing: true)
          end
          [key, value]
        end

        def validate_parent!
          raise "parent.object is nil. Check the participatory space is saved. " if parent.object.nil?
          raise "parent.object do not respond to id. Did you sent a Participatory Space" unless parent.object.respond_to?(:id)
          raise "parent.object is not persisted" unless parent.object.persisted?
        end

        def import_images_container!
          parser.model_images_container.map do |name, asset_id|
            asset_data = parser.assets.find { |asset| asset["id"] == asset_id }
            next nil unless asset_data

            block_attachment = @object.images_container.send(:"#{name}")
            attachment_serializer = Decidim::CommunityTemplates::Importers::Attachment.new(
              TemplateParser.new(
                data: { **asset_data, name: "file" },
                translations: parser.translations,
                locales: parser.locales,
                assets: parser.assets,
                i18n_vars: parser.i18n_vars
              ),
              organization,
              user,
              parent: OpenStruct.new(object: block_attachment),
              for_demo: demo?
            )
            attachment = attachment_serializer.import!
            @after_import_serializers << attachment_serializer
            @object.images_container.send(:"#{name}=", attachment)
          end.compact
          @object.images_container.save
        end
      end
    end
  end
end
