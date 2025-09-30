# frozen_string_literal: true

require "git"

FactoryBot.define do
  factory :git, class: "Git::Base" do
    skip_create
    transient do
      path { Rails.root.join("tmp", "catalogs", "test_catalog_#{SecureRandom.hex(8)}") }
      configured { true }
      settings { build(:git_settings) }
    end

    initialize_with do
      FileUtils.rm_rf(path)
      FileUtils.mkdir_p(path)
      Git.init(path)
      g = Git.open(path)
      repo_branch = settings[:repo_branch] || "main"
      repo_url = settings[:repo_url] || Faker::Internet.url(scheme: "https")
      repo_author_name = settings[:repo_author_name] || Faker::Name.name
      repo_author_email = settings[:repo_author_email] || Faker::Internet.email
      g.checkout(repo_branch, new_branch: g.branches.local.none? { |branch| branch.name == repo_branch }) unless g.current_branch == repo_branch
      if configured
        g.config("remote.origin.url", repo_url)
        g.config("remote.origin.branch", repo_branch)
        g.config("user.name", repo_author_name)
        g.config("user.email", repo_author_email)
      end
      g
    end

    trait :with_commit do
      after(:build) do |git, options|
        commit_file = options.path.join("committed_#{SecureRandom.hex(8)}.md")
        File.write(commit_file, "hello world")
        git.add(commit_file)
        git.commit_all(":tada")
      end
    end

    trait :with_unstaged_file do
      after(:build) do |_git, options|
        FileUtils.touch(options.path.join("unstaged_#{SecureRandom.hex(8)}.md"))
      end
    end

    trait :with_staged_file do
      after(:build) do |git, options|
        staged_path = options.path.join("staged_#{SecureRandom.hex(8)}.md")
        FileUtils.touch(staged_path)
        git.add(staged_path)
      end
    end

    trait :with_modified_file do
      after(:build) do |git, options|
        modified_path = options.path.join("modified_#{SecureRandom.hex(8)}.md")
        File.write(modified_path, "version 1")
        git.add
        git.commit_all(":tada")
        File.write(modified_path, "version 2")
      end
    end

    trait :with_deleted_file do
      after(:build) do |git, options|
        deleted_path = options.path.join("deleted_#{SecureRandom.hex(8)}.md")
        FileUtils.touch(deleted_path)
        git.add(deleted_path)
        git.commit_all(":tada")
        FileUtils.rm(deleted_path)
      end
    end

    trait :with_renamed_file do
      after(:build) do |git, options|
        renamed_path = options.path.join("renamed_#{SecureRandom.hex(8)}.md")
        FileUtils.touch(renamed_path)
        git.add(renamed_path)
        git.commit_all(":tada")
        FileUtils.mv(renamed_path, path.join("renamed_#{SecureRandom.hex(8)}.md"))
      end
    end
  end
end
