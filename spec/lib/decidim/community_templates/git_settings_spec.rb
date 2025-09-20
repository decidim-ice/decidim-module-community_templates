# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe GitSettings do
      describe "#valid?" do
        it "returns false if the repo_author_email is not set" do
          git_mirror = build(:git_settings, repo_author_email: nil)
          expect(git_mirror).not_to be_valid
          expect(git_mirror.errors.full_messages).to include(match(/Repo author email cannot be blank/))
        end

        it "returns false if the repo_author_email is not a valid email" do
          git_mirror = build(:git_settings, repo_author_email: "not_an_email")
          expect(git_mirror).not_to be_valid
          expect(git_mirror.errors.full_messages).to include(match(/Repo author email is not a valid email/))
        end

        it "returns false if the repo_author_name is not set" do
          git_mirror = build(:git_settings, repo_author_name: nil)
          expect(git_mirror).not_to be_valid
          expect(git_mirror.errors.full_messages).to include(match(/Repo author name cannot be blank/))
        end

        it "returns false if the repo_author_name is not at least 3 characters" do
          git_mirror = build(:git_settings, repo_author_name: "ab")
          expect(git_mirror).not_to be_valid
          expect(git_mirror.errors.full_messages).to include(match(/Repo author name is too short/))
        end

        it "returns false if the repo_url is not set" do
          git_mirror = build(:git_settings, repo_url: nil)
          expect(git_mirror).not_to be_valid
          expect(git_mirror.errors.full_messages).to include(match(/Repo url cannot be blank/))
        end

        it "returns false if the repo_url is not a valid https url" do
          git_mirror = build(:git_settings, repo_url: "ssh://example.com")
          expect(git_mirror).not_to be_valid
          expect(git_mirror.errors.full_messages).to include(match(/Repo url is not a valid URL/))
        end

        it "returns false if repo_username is not set but repo_password is" do
          git_mirror = build(:git_settings, repo_username: "", repo_password: "password")
          expect(git_mirror).not_to be_valid
          expect(git_mirror.errors.full_messages).to include(match(/Repo username cannot be blank/))
        end

        it "returns false if repo_username is set but repo_password is not" do
          git_mirror = build(:git_settings, repo_username: "username", repo_password: "")
          expect(git_mirror).not_to be_valid
          expect(git_mirror.errors.full_messages).to include(match(/Repo password cannot be blank/))
        end
      end
    end
  end
end
