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

          created_template_source = ActiveRecord::Base.transaction do
            serializer = Decidim::CommunityTemplates::Serializers::ParticipatoryProcess.init(
              model: form.source,
              locales: [organization.default_locale],
              with_manifest: true,
              metadata: form.template.as_json
            )
            serializer.metadata_translations!
            path = Decidim::CommunityTemplates.catalog_path.join("shared")
            path = Decidim::CommunityTemplates.catalog_path if Decidim::CommunityTemplates.push_to_git?
            match = Decidim::CommunityTemplates::TemplateSource.find_by(source: form.source, organization:)
            match.update(updated_at: Time.current)
            Decidim::CommunityTemplates::GitMirror.instance.transaction do |git|
              serializer.save!(path)
              git.add(all: true)
              git.commit_all("release(#{form.template.version}): update template")
            end
            match
          end

          if Decidim::CommunityTemplates.apartment_compat?
            # as we are dropping shema, we can't do this in a transaction
            Decidim::CommunityTemplates::GitSyncronizerJob.perform_later
          else
            Decidim::CommunityTemplates::GitSyncronizer.call
          end

          broadcast(:ok, created_template_source)
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
