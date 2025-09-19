# frozen_string_literal: true

require "git"

FactoryBot.define do
  factory :git_mirror, class: "Decidim::CommunityTemplates::GitMirror" do
    skip_create

    repo_url { "https://github.com/decidim/decidim-module-community_templates.git" }
    repo_branch { "main" }
    repo_username { "decidim" }
    repo_password { "password" }
    repo_author_name { "Decidim" }
    repo_author_email { "decidim@example.org" }

    initialize_with do
      # Get the singleton instance and configure it
      git_mirror = Decidim::CommunityTemplates::GitMirror.instance
      git_mirror.configure(
        repo_url:,
        repo_branch:,
        repo_username:,
        repo_password:,
        repo_author_name:,
        repo_author_email:
      )

      # use a uniq path for each initialization
      unique_path = Rails.root.join("tmp", "catalogs", "test_catalog_#{SecureRandom.hex(8)}")
      git_mirror.catalog_path = unique_path

      git_mirror
    end

    trait :empty do
    end

    trait :ready do
      repo_url { "https://github.com/decidim/decidim-module-community_templates.git" }
      repo_branch { "main" }
      repo_username { "decidim" }
      repo_password { "password" }
      repo_author_name { "Decidim" }
      repo_author_email { "decidim@example.org" }

      after(:create) do |git_mirror|
        FileUtils.mkdir_p(git_mirror.catalog_path)
        # initialize a git with a commit.
        Git.init(git_mirror.catalog_path)
        git = Git.open(git_mirror.catalog_path)
        git.config("remote.origin.url", git_mirror.repo_url)
        git.config("remote.origin.branch", git_mirror.repo_branch)
        git.config("user.name", git_mirror.repo_author_name)
        git.config("user.email", git_mirror.repo_author_email)

        initialize_ready_catalog(git_mirror.catalog_path)
      end
    end
  end
end
