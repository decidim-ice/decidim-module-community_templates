# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe GitCatalogNormalizer do
      before do
        CommunityTemplates.configure do |config|
          config.git_settings[:url] = Faker::Internet.url(scheme: "https")
        end
        allow(Decidim::CommunityTemplates).to receive(:catalog_path).and_return(Pathname.new(Dir.mktmpdir))
      end

      it "does nothing if CommunityTemplates.git_settings[:url] is not set" do
        allow(GitMirror).to receive(:instance).and_return(nil)
        CommunityTemplates.configure do |config|
          config.git_settings[:url] = nil
        end
        expect(GitMirror).not_to have_received(:instance)
        expect(described_class.call).to have_key(:ok)
      end

      it "run a git clone if the catalog path does not exists" do
        git_mirror = create(:git_mirror, :empty)
        FileUtils.rm_rf(git_mirror.catalog_path)
        expect(Git).to receive(:clone).with(
          git_mirror.repo_url,
          git_mirror.catalog_path.to_s
        )
        described_class.call
      end

      it "does not clone if the catalog path exists" do
        git_mirror = create(:git_mirror, :with_commit)
        expect(Git).not_to receive(:clone)
        described_class.call
        expect(git_mirror.catalog_path).to exist
      end

      it "raises an error if the repository URL mismatch" do
        git_mirror = create(:git_mirror, :with_commit)
        # Change remote URL in git
        git_mirror.git.config("remote.origin.url", "https://github.com/decidim/another-repository.git")
        result = described_class.call

        expect(result).to have_key(:error)
        expect(result[:error]).to include("Repository URL mismatch")
      end

      it "when cloning an empty repository, it commit and push an initial repository" do
        git_mirror = create(:git_mirror, :empty)

        FileUtils.mkdir_p(git_mirror.catalog_path)
        Git.init(git_mirror.catalog_path.to_s)
        git_mirror.git.config("origin.url", git_mirror.repo_url)
        git_mirror.git.checkout("main", new_branch: true)
        expect(git_mirror).to be_empty

        described_class.call
        expect(git_mirror).not_to be_empty
        expect(git_mirror.git.log(1).execute.first.message).to eq(":tada: Add empty manifest.json")
        expect(git_mirror.catalog_path.join("README.md")).to exist
        expect(git_mirror.catalog_path.join("LICENSE.md")).to exist
        expect(git_mirror.catalog_path.join("CONTRIBUTE.md")).to exist
      end
    end
  end
end
