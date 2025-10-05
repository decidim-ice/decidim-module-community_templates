# frozen_string_literal: true

require_relative "spec_helpers/git_catalog_helpers"
require_relative "spec_helpers/run_initializer"
require "decidim/dev"

ENV["ENGINE_ROOT"] = File.dirname(__dir__)
ENV["NODE_ENV"] ||= "test"
ENV["DECIDIM_AVAILABLE_LOCALES"] = "en,ca,es,pt-BR"

Decidim::Dev.dummy_app_path = File.expand_path(File.join(__dir__, "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"
I18n.available_locales = ENV["DECIDIM_AVAILABLE_LOCALES"].split(",").map(&:to_sym)
Decidim.available_locales = I18n.available_locales

RSpec.configure do |config|
  config.include Decidim::CommunityTemplates::SpecHelpers::GitCatalogHelpers
  config.include Decidim::CommunityTemplates::SpecHelpers::RunInitializer
  config.after(:suite) do
    FileUtils.rm_rf(Rails.root.join("tmp/catalogs"))
  end
end
FactoryBot::SyntaxRunner.class_eval do
  include Decidim::CommunityTemplates::SpecHelpers::GitCatalogHelpers
end
