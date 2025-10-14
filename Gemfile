# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

# Inside the development app, the relative require has to be one level up, as
# the Gemfile is copied to the development_app folder (almost) as is.
base_path = ""
base_path = "../" if File.basename(__dir__) == "development_app"
base_path = "../../" if File.basename(__dir__) == "decidim_dummy_app"

require_relative "#{base_path}lib/decidim/community_templates/version"

DECIDIM_VERSION = Decidim::CommunityTemplates::DECIDIM_VERSION

gem "decidim", DECIDIM_VERSION
gem "decidim-community_templates", path: "."

gem "bootsnap", "~> 1.4"

gem "puma", ">= 6.3.1"
# temporary fix for simplecov
gem "rexml", "3.4.0"
gem "decidim-apartment", git: "https://gitlab.com/lappis-unb/decidimbr/infra/participa-gem"
gem "ros-apartment", require: "apartment"
gem "deface",
    git: "https://github.com/froger/deface",
    branch: "fix/js-overrides"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", DECIDIM_VERSION

  gem "brakeman", "~> 6.1"
  gem "parallel_tests", "~> 4.2"
  gem "rubocop-rails", "~> 2.25.1"
end

group :development do
  gem "letter_opener_web", "~> 2.0"
  gem "listen", "~> 3.1"
  gem "web-console", "~> 4.2"
end
