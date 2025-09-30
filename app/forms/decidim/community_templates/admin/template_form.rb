# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplateForm < Decidim::Form
        include TranslatableAttributes

        attribute :id, String
        translatable_attribute :name, String
        translatable_attribute :description, String
        attribute :version, String

        validates :id, presence: true
        validates :name, translatable_presence: true, if: ->(form) { form.id.present? && form.participatory_space }
        validates :description, translatable_presence: true, if: ->(form) { form.id.present? && form.participatory_space }
        validates :version, presence: true, if: ->(form) { form.id.present? && form.participatory_space }

        validate :valid_participatory_space
        validate :serializer_present
        validate :same_organization

        def participatory_space
          @space ||= begin
            GlobalID::Locator.locate(id)
          rescue StandardError
            nil
          end
        end

        def serializer
          @serializer ||= Decidim::CommunityTemplates.serializer_registry.find(participatory_space.class.name)&.serializer_class
        end

        # If name is not explicitly set, use the participatory space title
        def name
          return super if super.present?

          participatory_space.title if participatory_space
        end

        def metadata
          {
            name: name,
            description: description,
            version: version
          }
        end

        private

        def valid_participatory_space
          return if participatory_space

          errors.add(:participatory_space, :not_found)
        end

        def serializer_present
          return if serializer

          errors.add(:participatory_space, :unsupported)
        end

        def same_organization
          return unless participatory_space

          return if participatory_space.organization == context.current_organization

          errors.add(:participatory_space, :invalid)
        end
      end
    end
  end
end
