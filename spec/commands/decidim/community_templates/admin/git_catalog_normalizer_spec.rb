# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe GitCatalogNormalizer do
      let!(:git_settings) { create(:git_settings) }

      before do
        CommunityTemplates.configure do |config|
          config.git_settings[:url] = git_settings.attributes[:url]
        end
        Decidim::CommunityTemplates::GitMirror.instance.configure(
          git_settings.attributes
        )
        allow(Decidim::CommunityTemplates).to receive(:catalog_path).and_return(GitMirror.instance.catalog_path)
        allow(Decidim::CommunityTemplates).to receive(:enabled?).and_return(true)
      end

      it "run a git clone if the catalog path does not exists" do
        git_mirror = create(:git_mirror, :empty)
        git_mirror.catalog_path = Decidim::CommunityTemplates.catalog_path
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
        git_mirror.open_git.config("remote.origin.url", "https://github.com/decidim/another-repository.git")
        result = described_class.call

        expect(result).to have_key(:invalid)
        expect(result[:invalid]).to include("Repository URL mismatch")
      end
    end
  end
end
