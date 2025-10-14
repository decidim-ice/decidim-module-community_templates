# frozen_string_literal: true

namespace :decidim do
  namespace :community_templates do
    desc "Drop demo organization"
    task drop_demo: :environment do
      $stdout.sync = true
      $stderr.sync = true
      Rails.logger = ActiveSupport::Logger.new($stdout)
      Rails.logger.level = Logger::DEBUG
      Decidim::CommunityTemplates::DropDemo.call
    end
  end
end
