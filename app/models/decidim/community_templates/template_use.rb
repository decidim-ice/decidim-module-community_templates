# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class TemplateUse < ApplicationRecord
      self.table_name = "community_template_uses"
      belongs_to :organization, class_name: "Decidim::Organization", foreign_key: "decidim_organization_id"
      belongs_to :resource, polymorphic: true

      validates :template_id, presence: true, uniqueness: true

      validate :resource_type_allowed
      validate :resource_not_changed, if: :persisted?
      validate :resource_uniqueness, unless: :persisted?
      validate :resource_in_organization, unless: :persisted?
      validate :template_is_uuid

      private

      def allowed_resources
        Decidim::CommunityTemplates.serializers.map { |serializer| serializer[:model] }
      end

      def resource_type_allowed
        return if resource_type.blank?

        errors.add(:resource, :inclusion, allowed_resources: allowed_resources.join(", ")) unless allowed_resources.include?(resource_type)
      end

      def resource_not_changed
        errors.add(:resource, :changed) if resource_id_changed? || resource_type_changed?
      end

      def resource_uniqueness
        match = self.class.exists?(resource_id: resource_id, resource_type: resource_type, decidim_organization_id: organization&.id)
        errors.add(:resource, :taken) if match
      end

      def resource_in_organization
        return unless resource.present? && organization.present?

        errors.add(:resource, :not_in_organization) unless resource.organization == organization
      end

      def template_is_uuid
        return if template_id.blank?

        errors.add(:template_id, :bad_format) unless template_id.match?(Decidim::CommunityTemplates::Template::UUID_REGEX)
      end
    end
  end
end
