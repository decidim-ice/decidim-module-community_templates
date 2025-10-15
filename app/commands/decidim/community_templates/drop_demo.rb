# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class DropDemo < ::Decidim::Command
      def call
        Rails.logger.info("Dropping #{Decidim::CommunityTemplates.config.demo[:host]} organization")

        if Decidim::CommunityTemplates.apartment_compat?
          distribution_key = Decidim::Apartment::DistributionKey.for_host(Decidim::CommunityTemplates.config.demo[:host])
          return unless distribution_key

          # Drop the schema, will drop all associated data.
          distribution_key.destroy!
          return ::Apartment::Tenant.drop(distribution_key.key)
        end

        ActiveRecord::Base.transaction do
          Decidim::CommunityTemplates.with_demo_organization do |organization|
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
          end
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
    end
  end
end
