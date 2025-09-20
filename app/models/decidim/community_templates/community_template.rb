# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class CommunityTemplate < ApplicationRecord
      self.table_name = "community_templates"
      before_validation :ensure_uuid
      belongs_to :organization, class_name: "Decidim::Organization", foreign_key: "decidim_organization_id"
      belongs_to :source, polymorphic: true

      validates :author, presence: true
      validates :title, presence: true
      validates :version, presence: true
      validates :short_description, presence: true
      validate :source_type_allowed
      validate :source_not_changed, if: :persisted?
      validate :source_uniqueness, unless: :persisted?
      validate :uuid_not_changed, if: :persisted?

      private

      def ensure_uuid
        self.uuid = SecureRandom.uuid if uuid.blank?
      end

      def allowed_sources
        Decidim::CommunityTemplates.serializers.map { |serializer| serializer[:model] }
      end

      def source_type_allowed
        return if source_type.blank?

        errors.add(:source, :inclusion, allowed_sources: allowed_sources.join(", ")) unless allowed_sources.include?(source_type)
      end

      def source_uniqueness
        match = self.class.exists?(source_id: source_id, source_type: source_type, decidim_organization_id: organization&.id)
        errors.add(:source, :taken) if match
      end

      def source_not_changed
        errors.add(:source, :changed) if source_id_changed? || source_type_changed?
      end

      def uuid_not_changed
        errors.add(:uuid, :changed) if uuid_changed?
      end
    end
  end
end
