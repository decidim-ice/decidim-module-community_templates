# frozen_string_literal: true

require "git"

FactoryBot.define do
  factory :git_settings, class: "Decidim::CommunityTemplates::GitSettings" do

    repo_url { "https://github.com/decidim/decidim-module-community_templates.git" }
    repo_branch { "main" }
    repo_username { "decidim" }
    repo_password { "password" }
    repo_author_name { "Decidim" }
    repo_author_email { "decidim@example.org" }

  end
end
