# frozen_string_literal: true

require "git"

FactoryBot.define do
  factory :git_mirror, class: "Decidim::CommunityTemplates::GitMirror" do
    skip_create

    transient do
      catalog_path { Rails.root.join("tmp", "catalogs", "test_catalog_#{SecureRandom.hex(8)}") }
      settings_attributes { {} }
      git_instance { create(:git, path: catalog_path, settings: settings.attributes) }
    end

    settings { build(:git_settings, settings_attributes) }

    initialize_with do
      # Get the singleton instance and configure it
      git_mirror = Decidim::CommunityTemplates::GitMirror.instance
      git_mirror.settings = settings

      # use a uniq path for each initialization
      git_mirror.catalog_path = catalog_path
      git_instance
      git_mirror
    end

    trait :empty do
      # Empty trait for testing empty state
      after(:initialize) do |git_mirror|
        FileUtils.rm_rf(git_mirror.catalog_path)
      end
    end

    trait :with_commit do
      git_instance { build(:git, :with_commit, path: catalog_path, settings: settings.attributes) }
    end

    trait :with_unstaged_file do
      git_instance { build(:git, :with_unstaged_file, path: catalog_path, settings: settings.attributes) }
    end

    trait :with_staged_file do
      git_instance { build(:git, :with_staged_file, path: catalog_path, settings: settings.attributes) }
    end

    trait :with_modified_file do
      git_instance { build(:git, :with_modified_file, path: catalog_path, settings: settings.attributes) }
    end

    trait :with_deleted_file do
      git_instance { build(:git, :with_deleted_file, path: catalog_path, settings: settings.attributes) }
    end

    trait :with_renamed_file do
      git_instance { build(:git, :with_renamed_file, path: catalog_path, settings: settings.attributes) }
    end
  end
end
