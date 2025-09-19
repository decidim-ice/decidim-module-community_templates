# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class CreateTemplate < Decidim::Command
        def initialize(form)
          @form = form
          @errors = []
        end
        attr_reader :form, :errors

        delegate :participatory_space, :metadata, to: :form

        def call
          return broadcast(:invalid, form.errors.full_messages.to_sentence) if form.invalid?

          create_template!
          return broadcast(:invalid, errors.to_sentence) if errors.any?

          broadcast(:ok)
        end

        private

        def serializer
          @serializer ||= form.serializer.new(model: participatory_space, metadata:, locales: current_organization.available_locales)
        end

        def create_template!
          serializer.save!("#{CommunityTemplates.local_path}/local")
        rescue StandardError => e
          @errors << e.message
          Rails.logger.error("[Decidim::CommunityTemplates] Error creating template: #{e.message}")
        end
      end
    end
  end
end
