# frozen_string_literal: true

require "git"

FactoryBot.define do
  factory :git_settings, class: "Decidim::CommunityTemplates::GitSettings" do
    skip_create
    repo_url { "#{Faker::Internet.url(scheme: "https")}.git" }
    repo_branch { "main" }
    repo_username { Faker::Internet.username }
    repo_password { Faker::Internet.password }
    repo_author_name { Faker::Name.name }
    repo_author_email { Faker::Internet.email }
  end
end
