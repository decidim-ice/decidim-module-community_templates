# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class CreateCommunityTemplateCommand < Decidim::Command
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
        rescue StandardError => e
          Rails.logger.error "Error writing template: #{e.message}"
          add_specific_error(e)
          # Rollback file
          form.template.delete(Decidim::CommunityTemplates.catalog_path)
          broadcast(:invalid)
        end

        private

        def add_specific_error(error)
          i18n_scope = "decidim.community_templates.admin.template_create.errors"
          case error
          when Errno::ENOENT
            form.errors.add(:base, I18n.t("file_not_found", scope: i18n_scope))
          when Errno::ENOSPC
            form.errors.add(:base, I18n.t("no_space", scope: i18n_scope))
          when Errno::EACCES
            form.errors.add(:base, I18n.t("permission_denied", scope: i18n_scope))
          when Errno::ENAMETOOLONG
            form.errors.add(:base, I18n.t("name_too_long", scope: i18n_scope))
          when Errno::EROFS
            form.errors.add(:base, I18n.t("read_only_filesystem", scope: i18n_scope))
          else
            form.errors.add(:base, I18n.t("unknown", scope: i18n_scope))
          end
        end
      end
    end
  end
end
