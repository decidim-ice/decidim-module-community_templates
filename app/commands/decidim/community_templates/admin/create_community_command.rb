# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class CreateCommunityCommand < Decidim::Command
        attr_reader :form, :organization

        def initialize(form, organization)
          @form = form
          @organization = organization
        end

        def call
          return broadcast(:invalid) if form.invalid?

          ActiveRecord::Base.transaction do
            # Create a TemplateSource
            TemplateSource.create!(
              source: form.source,
              template_id: form.template.id,
              organization: organization
            )
            form.template.owned = true
            # Write the template to the catalog
            form.template.write(Decidim::CommunityTemplates.catalog_path)
          end

          broadcast(:ok)
        rescue StandardError
          # Rollback file
          form.template.delete(Decidim::CommunityTemplates.catalog_path)
          broadcast(:invalid)
        end
      end
    end
  end
end
