# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    ##
    # Hold data about a template.
    # Offer read/write method to handle files in a specific template folder.
    class TemplateMetadata
      include ActiveModel::Model
      include Decidim::AttributeObject::Model
      UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

      attribute :default_locale, String, default: I18n.default_locale.to_s
      attribute :id, String
      attribute :name, String
      attribute :description, String
      attribute :version, String
      attribute :author, String
      attribute :links, Array[String]
      attribute :@class, String
      attribute :community_templates_version, String
      attribute :decidim_version, String
      attribute :archived_at, DateTime
      attribute :owned, Boolean, default: false
      attribute :updated_at, DateTime
      attribute :created_at, DateTime, default: -> { Time.current }

      validates :id, presence: true, format: { with: UUID_REGEX }
      validates :name, presence: true
      validates :description, presence: true
      validates :version, presence: true
      validates :author, presence: true
      validates :@class, presence: true, inclusion: { in: Decidim::CommunityTemplates.serializers.map { |serializer| serializer[:model] } }
      validates :community_templates_version, presence: true
      validates :decidim_version, presence: true
      validates :created_at, presence: true
      validates :updated_at, comparison: { greater_than_or_equal_to: :created_at }, allow_nil: true, if: -> { created_at.present? }
      validate :validate_link_well_formed
      alias template_id id
      alias template_id= id=

      def archived?
        archived_at.present?
      end

      def normalized_links
        links_array = links.map { |l| l.split(", ") }.flatten
        links_array.map { |l| l.strip.chomp("/") }
      end

      def compatible?
        Decidim.version >= decidim_version && community_templates_version <= Decidim::CommunityTemplates::VERSION
      end

      def public_url(host)
        "https://#{host}/catalog/#{id}"
      end

      def self.find(template_id)
        from_path(Decidim::CommunityTemplates.catalog_path.join(template_id))
      end

      def self.from_path(template_path)
        parsed_template = TemplateParser.new(template_path)
        template = parsed_template.template
        template.validate!
        template
      end

      def metadatas
        raise ActiveModel::ValidationError, self unless valid?
        return unless owned?

        as_json.merge(
          created_at: created_at || Time.current,
          updated_at: updated_at || Time.current
        )
      end

      def delete(catalog_path)
        return unless owned?

        template_path = catalog_path.join(id)
        FileUtils.rm_rf(template_path)
      end

      def validate_link_well_formed
        return if normalized_links.blank?

        normalized_links.each do |link|
          uri = URI.parse(link)
          errors.add(:links, :bad_format) unless uri.is_a?(URI::HTTPS) && uri.host.present?
        rescue URI::InvalidURIError
          errors.add(:links, :bad_format)
        end
      end

      def to_json(*)
        as_json(*).to_json
      end

      def as_json(*)
        json = super
        json["links"] = normalized_links
        json.delete("owned")
        json
      end
    end
  end
end
