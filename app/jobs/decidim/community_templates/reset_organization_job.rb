# frozen_string_literal: true

module Decidim
  module CommunityTemplates      
    class ResetOrganizationJob < ApplicationJob
        attr_reader :organization
        discard_on Decidim::CommunityTemplates::ResetOrganizationError


        def perform
          purge! if organization
          @organization = nil
          created_organization = create_organization!
          if created_organization
            Rails.logger.info("Setting up default admin user")
            author.update(nickname: "demo_admin", password: "decidim123456789", password_confirmation: "decidim123456789")
            author.skip_confirmation!
            author.save!
            Rails.logger.info("Import templates")
            import_templates!
            return created_organization
          else
            raise ResetOrganizationError, "Failed to recreate demo organization"
          end
        end

        private 

        def organization
          @organization = Decidim::CommunityTemplates.demo_organization
        end
        def purge!
          ActiveRecord::Base.transaction do
            Decidim::StaticPage.where(organization: organization).count
            Decidim::StaticPage.where(organization: organization).delete_all
            Rails.logger.info("Purged #{Decidim::StaticPage.where(organization: organization).count} static pages")

            Decidim::EditorImage.where(organization: organization).count
            Decidim::EditorImage.where(organization: organization).delete_all
            Rails.logger.info("Purged #{Decidim::EditorImage.where(organization: organization).count} editor images")

            identities_count = 0
            Decidim::User.where(organization: organization).find_each do |user|
              identities_count += user.identities.count
              user.identities.delete_all
            end
            Rails.logger.info("Purged #{identities_count} identities")
            Decidim::User.where(organization: organization).delete_all
            Rails.logger.info("Purged #{Decidim::User.where(organization: organization).count} users")


            Decidim::User.where(organization: organization).count
            Decidim::User.where(organization: organization).delete_all
            Rails.logger.info("Purged #{Decidim::User.where(organization: organization).count} users")

            Decidim::ParticipatoryProcess.where(organization: organization).count
            Decidim::ParticipatoryProcess.where(organization: organization).delete_all
            Rails.logger.info("Purged #{Decidim::ParticipatoryProcess.where(organization: organization).count} participatory processes")

            Decidim::CommunityTemplates::TemplateUse.where(organization: organization).count
            Decidim::CommunityTemplates::TemplateUse.where(organization: organization).delete_all
            Decidim::CommunityTemplates::TemplateSource.where(organization: organization).count
            Decidim::CommunityTemplates::TemplateSource.where(organization: organization).delete_all

            organization.destroy!
          rescue StandardError => e
            Rails.logger.info { "  Error processing organization #{organization.name}: #{e.message}" }
            Rails.logger.info "  Rolling back transaction..."
            raise e
          end

          begin
            Rake::Task["decidim:upgrade:clean:invalid_records"].invoke
          rescue StandardError => e
            Rails.logger.info("Error running cleanup task: #{e.message}")
          end
        end

        def author
          @author ||= Decidim::User.find_by(email: "admin@example.org", organization: Decidim::CommunityTemplates.demo_organization)
        end

        def import_templates!
          organization = Decidim::CommunityTemplates.demo_organization
          # For all templates in catalog, import.
          templates = Decidim::CommunityTemplates.catalog_path.children.select do |child|
            child.directory? && child.basename.to_s.match?(Decidim::CommunityTemplates::TemplateMetadata::UUID_REGEX)
          end.uniq
          Rails.logger.info("Importing #{templates.count} templates in #{organization.host}")
          templates.each do |template_path|
            parser = Decidim::CommunityTemplates::TemplateExtractor.init(
              template_path: template_path.to_s,
              locales: organization.available_locales
            ).parser
            Rails.logger.info("Import #{parser.name} template")
            process = Decidim::CommunityTemplates::Importers::ParticipatoryProcess.new(parser, organization, author).import!
            process.update!(
              slug: "t-#{parser.template.id}",
              published_at: Time.current
            )
            process
          rescue StandardError => e
            Rails.logger.info("Error importing #{template_path}: #{e.message}")
            Rails.logger.info(e.backtrace.join("\n"))
          end
        end

        def create_organization!
          default_locale = I18n.default_locale.to_s
          available_locales = [default_locale]
          name = Decidim::CommunityTemplates.config.demo[:name]

          form_params = {
            name: name,
            host: Decidim::CommunityTemplates.config.demo[:host],
            available_locales: available_locales,
            default_locale: default_locale,
            reference_prefix: name.parameterize.upcase,
            time_zone: "UTC",
            smtp_settings: {},
            file_upload_settings: {},
            force_users_to_authenticate_before_access_organization: false,
            available_authorizations: [],
            users_registration_mode: "disabled",
            organization_admin_email: "admin@example.org",
            organization_admin_name: "Demo Admin",
            content_type_allowlist: %w(image/jpeg image/gif image/png)
          }
          form = Decidim::System::RegisterOrganizationForm.new(form_params)
          if form.valid?
            result = Decidim::System::CreateOrganization.call(form)
            if result.has_key?(:ok) && result[:ok]
              org = Decidim::CommunityTemplates.demo_organization
              org.file_upload_settings = Decidim::OrganizationSettings.default(:upload)
              org.colors = {
                primary: Decidim::CommunityTemplates.config.demo[:primary_color] || "#14342B",
                secondary: Decidim::CommunityTemplates.config.demo[:secondary_color] || "#006482",
                tertiary: Decidim::CommunityTemplates.config.demo[:tertiary_color] || "#F7E733"
              }.compact_blank
              org.save!
              return org
            end
            Rails.logger.info("  Failed to create demo organization: #{name}")
            Rails.logger.info("  Errors: #{result[:invalid].inspect}")
          else
            Rails.logger.info("  Validation failed for demo organization: #{name}")
            Rails.logger.info("  Errors: #{form.errors.full_messages.join(", ")}")
          end
          nil
        end
    end
  end
end
