# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class ResetOrganization < ::Decidim::Command
      def call
        @organization = nil
        create_organization!
        with_tmp_organization do |organization|
          raise ResetOrganizationError, "Failed to recreate demo organization, organization not found" unless organization

          Rails.logger.info("Setting up default admin user")
          author = Decidim::User.find_by(admin: true, organization:)
          author.update(nickname: "john_doe", password: "DemoAdmin123456789!", password_confirmation: "DemoAdmin123456789!")
          author.skip_confirmation!
          author.save!
          Rails.logger.info("Import templates")
          import_templates!(organization)
        end
        # Swap the organization
        DropDemo.call
        update_host!
      end

      def update_host!
        if Decidim::CommunityTemplates.apartment_compat?
          distribution_key = Decidim::Apartment::DistributionKey.for_host(tmp_host)
          distribution_key.update(host: Decidim::CommunityTemplates.config.demo[:host])
          distribution_key.save!
          distribution_key.switch do
            organization = Decidim::Organization.last
            organization.update(
              host: Decidim::CommunityTemplates.config.demo[:host],
              name: { organization.default_locale => Decidim::CommunityTemplates.config.demo[:name] },
              reference_prefix: Decidim::CommunityTemplates.config.demo[:name].parameterize.upcase
            )
            organization.save!
            Rails.logger.debug { "Organization updated: #{organization.host}" }
            Rails.logger.debug { "Organization name: #{organization.name}" }
            Rails.logger.debug { "Organization reference prefix: #{organization.reference_prefix}" }
          end
        else
          organization = Decidim::Organization.find_by(host: tmp_host)
          organization.update(
            host: Decidim::CommunityTemplates.config.demo[:host],
            name: { organization.default_locale => Decidim::CommunityTemplates.config.demo[:name] },
            reference_prefix: Decidim::CommunityTemplates.config.demo[:name].parameterize.upcase
          )
          organization.save!
          Rails.logger.debug { "Organization updated: #{organization.host}" }
          Rails.logger.debug { "Organization name: #{organization.name}" }
          Rails.logger.debug { "Organization reference prefix: #{organization.reference_prefix}" }
        end
      end

      def tmp_host
        @tmp_host ||= "tmp-#{SecureRandom.hex(4)}.decidim.org"
      end

      def with_tmp_organization
        if Decidim::CommunityTemplates.apartment_compat?
          Decidim::Apartment::DistributionKey.for_host(tmp_host).switch do
            yield Decidim::Organization.last
          end
        else
          yield Decidim::Organization.create!(host: tmp_host)
        end
      end

      private

      def import_templates!(organization)
        author = Decidim::User.find_by(email: "admin@example.org", organization:)
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
          process = Decidim::CommunityTemplates::Importers::ParticipatoryProcess.new(
            parser,
            organization,
            author
          ).import!
          process.slug = "t-#{parser.template.id}"
          process.published_at = Time.current
          Rails.logger.info("Invalid participatory process: #{process.errors.full_messages.join(", ")} [slug: #{process.slug}]") if process.invalid?
          process.save!
          process
        rescue StandardError => e
          Rails.logger.info("Error importing #{template_path}: #{e.message}")
          Rails.logger.info(e.backtrace.join("\n"))
          raise e
        end
      end

      def create_organization!
        default_locale = Decidim::CommunityTemplates.config.demo[:default_locale]

        available_locales = [default_locale]

        name = "#{Decidim::CommunityTemplates.config.demo[:name]} #{SecureRandom.hex(4)} #{Time.current.strftime("%Y%m%d%H%M%S")}"

        form_params = {
          name: name,
          host: tmp_host,
          available_locales: available_locales,
          default_locale: default_locale,
          reference_prefix: name.parameterize.upcase,
          time_zone: "UTC",
          smtp_settings: {},
          file_upload_settings: {},
          force_users_to_authenticate_before_access_organization: false,
          available_authorizations: [],
          users_registration_mode: "enabled",
          organization_admin_email: "admin@example.org",
          organization_admin_name: "John Doe",
          content_type_allowlist: %w(image/jpeg image/gif image/png)
        }
        form = Decidim::System::RegisterOrganizationForm.new(form_params)
        if form.valid?
          result = Decidim::System::CreateOrganization.call(form)
          if result.has_key?(:ok) && result[:ok]
            return with_tmp_organization do |organization|
              organization.file_upload_settings = Decidim::OrganizationSettings.default(:upload)
              organization.colors = {
                primary: Decidim::CommunityTemplates.config.demo[:primary_color] || "#14342B",
                secondary: Decidim::CommunityTemplates.config.demo[:secondary_color] || "#006482",
                tertiary: Decidim::CommunityTemplates.config.demo[:tertiary_color] || "#F7E733"
              }.compact_blank
              organization.save!
            end
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
