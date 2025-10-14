# frozen_string_literal: true

namespace :decidim do
  namespace :community_templates do
    desc "Reset demo organizations - purge and recreate template demo organizations"
    task reset_demo: :environment do
      $stdout.sync = true
      $stderr.sync = true
      Rails.logger = ActiveSupport::Logger.new($stdout)
      Rails.logger.level = Logger::DEBUG
      Rails.logger.info "Starting reset_demo task"
      Rails.logger.debug "Logger configured for rake task"

      Decidim::CommunityTemplates::GitCatalogNormalizer.call
      Decidim::CommunityTemplates::GitSyncronizerJob.perform_now
      Decidim::CommunityTemplates::ResetOrganizationJob.perform_now
    end
  end
end
