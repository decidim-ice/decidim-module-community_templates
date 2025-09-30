# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    ##
    # Persist the relation between a template and its source.
    # Source can be a participatory process, an assembly, etc.
    # This is used to determine if a template is owned by an organization.
    class TemplateSource < ApplicationRecord
      self.table_name = "community_template_sources"
      belongs_to :organization, class_name: "Decidim::Organization", foreign_key: "decidim_organization_id"
      belongs_to :source, polymorphic: true

      validates :template_id, presence: true, uniqueness: true

      validate :source_type_allowed
      validate :source_not_changed, if: :persisted?
      validate :source_uniqueness, unless: :persisted?
      validate :source_in_organization, unless: :persisted?
      validate :template_is_uuid

      def template
        @template ||= Decidim::CommunityTemplates::TemplateMetadata.find(template_id)
      end

      private

      def allowed_sources
        Decidim::CommunityTemplates.serializers.map { |serializer| serializer[:model] }
      end

      def source_type_allowed
        return if source_type.blank?

        errors.add(:source, :inclusion, allowed_sources: allowed_sources.join(", ")) unless allowed_sources.include?(source_type)
      end

      def source_not_changed
        errors.add(:source, :changed) if source_id_changed? || source_type_changed?
      end

      def source_uniqueness
        match = self.class.exists?(source_id: source_id, source_type: source_type, decidim_organization_id: organization&.id)
        errors.add(:source, :taken) if match
      end

      def source_in_organization
        return unless source.present? && organization.present?

        errors.add(:source, :not_in_organization) unless source.organization == organization
      end

      def template_is_uuid
        return if template_id.blank?

        errors.add(:template_id, :bad_format) unless template_id.match?(Decidim::CommunityTemplates::TemplateMetadata::UUID_REGEX)
      end
    end
  end
end
