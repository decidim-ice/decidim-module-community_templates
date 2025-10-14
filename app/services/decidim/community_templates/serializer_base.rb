# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class SerializerBase
      def initialize(model:, metadata: {}, locales: Decidim.available_locales, with_manifest: false)
        @model = model
        @metadata = metadata.with_indifferent_access
        @locales = locales
        @with_manifest = with_manifest
        # Hash: structure to hold all translations for the serialized object
        @translations = {}
        # Hash: structure to hold the final serialized data
        @data = {}
        # Hash: model-specific attributes
        @attributes = {}
        # Array: implement if necessary to include demo data
        @demo = []
        @assets = []
      end

      attr_reader :model, :translations, :attributes, :assets, :metadata, :locales, :with_manifest, :data, :demo

      delegate :as_json, to: :data

      def self.init(**args)
        serializer = new(**args)
        serializer.data!
        serializer.demo!
        serializer.assets!
        serializer.process_translations!
        serializer
      end

      # For the moment, name and description are the only translatable metadata fields
      def metadata_translations!
        %w(name description).each do |field|
          translations.deep_merge!(hash_to_i18n(metadata[field], field, "metadata"))
        end
        translations
      end

      # A unique random identifier with very low collision probability for the serialized object
      def id
        return metadata[:id] if metadata[:id].present?

        @id ||= begin
          alternatives = []
          alternatives << model.slug if model.respond_to?(:slug)
          alternatives << model.manifest_name if model.respond_to?(:manifest_name)
          alternatives << model.manifest.name if model.respond_to?(:manifest)
          alternatives << model.created_at.strftime("%Y%m%d%H%M%S") if model.respond_to?(:created_at)

          alternatives.find(&:present?)
        end
      end

      # metadata for the serialized object, extend in subclasses using super
      # Other possible future fields here could define rules for generating the final object
      # (e.g. how to generate the slug, or publication status)
      def data!
        data[:id] = id
        data[:@class] = model.class.name
        data[:attributes] = attributes
        return unless with_manifest

        data[:name] = "#{id}.metadata.name" if metadata[:name].present?
        data[:description] = "#{id}.metadata.description" if metadata[:description].present?
        data[:version] = metadata[:version]
        data.merge!(metadata.except(:name, :description, :version))
        data[:decidim_version] = Decidim.version
        data[:community_templates_version] = Decidim::CommunityTemplates::VERSION
      end

      def demo!
        # TODO
      end

      def assets!; end

      def json_files
        {
          data:,
          demo:
        }
      end

      # copies the serialized data into a template folder unto the given path
      def save!(destination_path)
        path = File.join(destination_path, id)

        json_files.each do |key, content|
          FileUtils.mkdir_p(path)
          file_path = File.join(path, "#{key}.json")
          File.write(file_path, JSON.pretty_generate(content))
        end

        save_assets!(path)

        translations.each do |lang, texts|
          lang_path = File.join(path, "locales")
          FileUtils.mkdir_p(lang_path)
          file_path = File.join(lang_path, "#{lang}.yml")
          File.write(file_path, { lang => texts }.to_yaml)
        end
      end

      def process_translations!
        # Check all translation and translate any active storage file with a %{filename} value
        translations.each do |_lang, texts|
          texts.each do |key, value|
            texts[key] = replace_active_storage_url(value)
          end
        end
      end

      def replace_active_storage_url(value)
        return value unless value.is_a?(String) || value.is_a?(Hash)

        if value.is_a?(Hash)
          transformed_values = value.map do |key, v|
            [key, replace_active_storage_url(v)]
          end
          return transformed_values.to_h
        end
        # match the Decidim::EditorImage attachment that match the org and the url
        # serializer the editor image in assets
        # replace it with %{filename}
        return value unless value.include?("/rails/active_storage/blobs/redirect")

        # find all the /rails/active_storage/blobs/redirect/path in the value
        new_value = value.dup
        value.scan(%r{src="(/rails/active_storage/blobs/redirect/([^/]+)[^"]+)"}).each do |match|
          # find the Decidim::EditorImage attachment that match the org and the url
          blob = ActiveStorage::Blob.find_signed(match[1])
          link = (match[0]).to_s
          attachment_join = <<~SQL.squish
            INNER JOIN
              active_storage_attachments
            ON
              active_storage_attachments.record_type = 'Decidim::EditorImage'
              AND active_storage_attachments.record_id = decidim_editor_images.id
          SQL
          blob_join = <<~SQL.squish
            INNER JOIN active_storage_blobs
            ON
              active_storage_blobs.id = active_storage_attachments.blob_id
          SQL
          editor_image = EditorImage.joins(attachment_join)
                                    .joins(blob_join)
                                    .where(active_storage_blobs: { id: blob.id })
                                    .first
          return new_value.gsub(link, "/apple-touch-icon.png") unless editor_image.present?
          reference_asset(editor_image.file.attachment)
          filename = Serializers::Attachment.filename(editor_image.file)
          i18n_key = filename.parameterize.underscore

          # replace it with %{filename} to be populated on import
          new_value = new_value.gsub(link, "%{#{i18n_key}}")
        end
        new_value
      end

      def relative_date(date)
        return nil if date.blank?
        Time.zone.now.to_i - date.to_i
      end

      private

      def save_assets!(path)
        assets_dir = Pathname.new(File.join(path, "assets"))
        FileUtils.mkdir_p(assets_dir)
        file_path = File.join(path, "assets.json")
        File.write(file_path, JSON.pretty_generate({
                                                     assets: @assets.select{ |serializer| serializer.attributes.present? }.as_json
                                                   }))

        FileUtils.chdir(assets_dir) do
          used_filenames = @assets.map do |serializer|
            next if serializer.nil? || serializer.blob.nil?
            File.open(serializer.filename, "wb") do |file|
              serializer.blob.download do |content|
                file.write(content)
              end
            end
            serializer.filename
          end

          # Remove unused filenames
          unused_filenames = assets_dir.children.map { |file| File.basename(file) } - used_filenames
          unused_filenames.each do |filename|
            FileUtils.rm(filename)
          end
        end
      end

      def id_parts
        id.to_s.split(".")
      end

      def i18n_field(field, value = nil, prefix = "attributes")
        value ||= model.send(field)
        unless value.is_a?(Hash)
          value = {
            locales.first => value
          }
        end

        translations.deep_merge!(hash_to_i18n(value, field, prefix))

        "#{id}.#{prefix}.#{field}"
      end

      def hash_to_i18n(hash, field, prefix = "attributes")
        hash = { locales.first => hash } unless hash.is_a?(Hash)

        locales.index_with do |lang|
          (id_parts + [prefix, field.to_s]).reverse.inject(hash[lang]) { |value, key| { key => value } }
        end
      end

      def append_serializer(serializer_class, model, prefix)
        inject_serializer(serializer_class, model, "#{id}.attributes.#{prefix}")
      end

      def reference_asset(attachment)
        inject_serializer(
          Serializers::Attachment,
          attachment,
          Serializers::Attachment.filename(attachment)
        )[:id]
      end

      def inject_serializer(serializer_class, model, serializer_id)
        serializer = serializer_class.init(model:, metadata: { id: serializer_id }, locales:)
        translations.deep_merge!(serializer.translations)
        @assets += serializer.assets
        serializer.data
      end
    end
  end
end
