# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplateForm < Decidim::Form
        attribute :participatory_space_id, String

        validates :participatory_space_id, presence: true
        validate :valid_participatory_space
        validate :serializer_present
        validate :same_organization

        def participatory_space
          @space ||= GlobalID::Locator.locate(participatory_space_id)
        end

        def serializer
          @serializer ||= Decidim::CommunityTemplates.serializer_registry.find(participatory_space.class.name)&.serializer_class
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
