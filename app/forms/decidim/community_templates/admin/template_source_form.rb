# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplateSourceForm < Decidim::Form
        attribute :source_id, String

        attribute :template, Decidim::CommunityTemplates::Template

        validates :source_id, presence: true
        validates :template, presence: true
        validate :valid_source

        def source
          @source ||= GlobalID::Locator.locate(source_id)
        end

        def valid_source
          return if source

          errors.add(:source, :not_found)
        end
      end
    end
  end
end
