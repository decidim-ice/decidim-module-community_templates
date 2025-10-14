# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class ImportTemplate < Decidim::Command
        def initialize(form)
          @form = form
          @organization = form.context.current_organization
          @user = form.context.current_user
        end
        attr_reader :form, :organization, :user

        def call
          return broadcast(:invalid, form.errors.full_messages.to_sentence) if form.invalid?

          transaction do
            template_id = form.id
            metas = Decidim::CommunityTemplates::TemplateMetadata.find(template_id)
            metas.validate!
            importer.import!
            TemplateUse.create!(
              template_id: form.id,
              organization: organization,
              resource: importer.object
            )
          end
          broadcast(:ok, importer.object)
        rescue StandardError => e
          Rails.logger.error "ImportTemplate error: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")        
          return broadcast(:invalid, e.message)
        end

        private

        def importer
          @importer ||= form.importer.new(form.parser, organization, user)
        end
      end
    end
  end
end
