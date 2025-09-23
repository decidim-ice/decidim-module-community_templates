# frozen_string_literal: true

require "git"

FactoryBot.define do
  factory :git_mirror, class: "Decidim::CommunityTemplates::GitMirror" do
    skip_create

    transient do
      settings_attributes { {} }
    end

    settings { build(:git_settings, settings_attributes) }

    initialize_with do
      # Get the singleton instance and configure it
      git_mirror = Decidim::CommunityTemplates::GitMirror.instance
      git_mirror.settings = settings

      # use a uniq path for each initialization
      unique_path = Rails.root.join("tmp", "catalogs", "test_catalog_#{SecureRandom.hex(8)}")
      git_mirror.catalog_path = unique_path

      git_mirror
    end

    trait :empty do
      # Empty trait for testing empty state
    end

    trait :ready do
      after(:create) do |git_mirror|
        path = git_mirror.catalog_path
        FileUtils.mkdir_p(path)
        # initialize a git with a commit.
        Git.init(path)
        git = Git.open(path)
        git.config("remote.origin.url", git_mirror.repo_url)
        git.config("remote.origin.branch", git_mirror.repo_branch)
        git.config("user.name", git_mirror.repo_author_name)
        git.config("user.email", git_mirror.repo_author_email)

        initialize_ready_catalog(git_mirror.catalog_path)
      end
    end
  end
end
