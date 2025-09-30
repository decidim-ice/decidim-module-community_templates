# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class UpdateCommunityTemplateCommand < Decidim::Command
        attr_reader :form, :organization

        def initialize(form, organization)
          @form = form
          @organization = organization
        end

        def call
          return broadcast(:invalid) if form.invalid?

          serializer = Decidim::CommunityTemplates::Serializers::ParticipatoryProcess.init(
            model: form.source,
            locales: [organization.default_locale],
            with_manifest: true,
            metadata: form.template.as_json
          )
          serializer.metadata_translations!
          serializer.save!(Decidim::CommunityTemplates.catalog_path)

          match = Decidim::CommunityTemplates::TemplateSource.find_by(source: form.source, organization:)
          match.update(updated_at: Time.current)

          GitSyncronizerJob.perform_now
          broadcast(:ok)
        rescue StandardError => e
          Rails.logger.error("[Decidim::CommunityTemplates] Error updating template: #{e.message}")
          add_specific_error(e)
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
