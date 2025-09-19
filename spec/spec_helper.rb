# frozen_string_literal: true

require_relative "spec_helpers/git_catalog_helpers"
require "decidim/dev"

ENV["ENGINE_ROOT"] = File.dirname(__dir__)
ENV["NODE_ENV"] ||= "test"

Decidim::Dev.dummy_app_path = File.expand_path(File.join(__dir__, "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"

RSpec.configure do |config|
  config.include Decidim::CommunityTemplates::SpecHelpers::GitCatalogHelpers

  config.after(:suite) do
    FileUtils.rm_rf(Rails.root.join("tmp/catalogs"))
  end
end
FactoryBot::SyntaxRunner.class_eval do
  include Decidim::CommunityTemplates::SpecHelpers::GitCatalogHelpers
end
