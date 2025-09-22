# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    ##
    # Hold data about a template.
    # Offer read/write method to handle files in a specific template folder.
    class Template
      include ActiveModel::Model
      include Decidim::AttributeObject::Model
      UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

      attribute :default_locale, String, default: I18n.default_locale.to_s
      attribute :id, String
      attribute :title, String
      attribute :short_description, String
      attribute :version, String
      attribute :author, String
      attribute :links, Array[String]
      attribute :source_type, String
      attribute :community_template_version, String
      attribute :decidim_version, String
      attribute :archived_at, DateTime
      attribute :owned, Boolean, default: false
      attribute :updated_at, DateTime
      attribute :created_at, DateTime, default: -> { Time.current }

      validates :id, presence: true, format: { with: UUID_REGEX }
      validates :title, presence: true
      validates :short_description, presence: true
      validates :version, presence: true
      validates :author, presence: true
      validates :source_type, presence: true, inclusion: { in: Decidim::CommunityTemplates.serializers.map { |serializer| serializer[:model] } }
      validates :community_template_version, presence: true
      validates :decidim_version, presence: true
      validates :created_at, presence: true
      validates :updated_at, comparison: { greater_than_or_equal_to: :created_at }, allow_nil: true, if: -> { created_at.present? }
      validate :link_well_formed

      def archived?
        archived_at.present?
      end

      def data
        raise NotImplementedError, "TODO: implement a TemplateData service"
      end

      def demo
        raise NotImplementedError, "TODO: implement a TemplateDemo service"
      end

      def compatible?
        Decidim.version >= decidim_version && community_template_version <= Decidim::CommunityTemplates::VERSION
      end

      def self.from_path(template_path)
        manifest_path = template_path.join("manifest.json")
        raise "Manifest file not found at #{manifest_path}" unless manifest_path.exist?

        manifest = JSON.parse(File.read(manifest_path))
        model = new(
          **manifest,
          owned: Decidim::CommunityTemplates::TemplateSource.exists?(template_id: manifest["id"].to_s)
        )
        model.validate!
        model
      end

      def write(catalog_path)
        raise ActiveModel::ValidationError, self unless valid?
        return unless owned?

        template_path = catalog_path.join(id)
        self.created_at ||= Time.current
        self.updated_at = Time.current

        FileUtils.mkdir_p(template_path)
        File.write(template_path.join("manifest.json"), JSON.pretty_generate(as_json))
      end

      def delete(catalog_path)
        return unless owned?

        in_use = Decidim::CommunityTemplates::TemplateSource.exists?(template_id: id)
        return if in_use

        template_path = catalog_path.join(id)
        FileUtils.rm_rf(template_path)
      end

      def link_well_formed
        return if links.blank?

        links.each do |link|
          uri = URI.parse(link)
          errors.add(:links, :bad_format) unless uri.is_a?(URI::HTTPS) && uri.host.present?
        rescue URI::InvalidURIError
          errors.add(:links, :bad_format)
        end
      end

      def to_json(*_args)
        attributes.to_json
      end

      def as_json(*_args)
        json = super
        json.delete("owned")
        json
      end
    end
  end
end
