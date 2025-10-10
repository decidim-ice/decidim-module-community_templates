# frozen_string_literal: true

require "spec_helper"
require "faker"

module Decidim
  module CommunityTemplates
    describe Engine do
      describe "decidim-community_templates.git_mirror initializer" do
        before do
          # Reset git_settings to default
          Decidim::CommunityTemplates.configure do |config|
            config.git_settings = {
              url: "",
              branch: "main",
              username: "",
              password: "",
              author_name: "Decidim Community Templates",
              author_email: "decidim-community-templates@example.org"
            }
          end
        end

        context "when git URL is not present" do
          it "does not configure git mirror" do
            expect(Decidim::CommunityTemplates::GitMirror).not_to receive(:instance)
            expect(Decidim::CommunityTemplates::GitCatalogNormalizer).not_to receive(:call)

            # Run the specific initializer
            run_initializer!("decidim-community_templates.git_mirror")
          end
        end

        context "when git URL is present" do
          let(:git_settings) do
            {
              url: ::Faker::Internet.url(scheme: "https"),
              branch: "main",
              username: ::Faker::Internet.username,
              password: ::Faker::Internet.password,
              author_name: ::Faker::Name.name,
              author_email: ::Faker::Internet.email
            }
          end

          let(:mock_mirror) { instance_double(Decidim::CommunityTemplates::GitMirror) }

          before do
            Decidim::CommunityTemplates.configure do |config|
              config.git_settings = git_settings
            end
            allow(Decidim::CommunityTemplates::GitMirror).to receive(:instance).and_return(mock_mirror)
            allow(mock_mirror).to receive(:configure).and_return(mock_mirror)
            allow(mock_mirror).to receive(:validate!)
            allow(Decidim::CommunityTemplates::GitCatalogNormalizer).to receive(:call)
          end

          it "configures git mirror with correct settings" do
            expect(mock_mirror).to receive(:configure).with(
              repo_url: git_settings[:url],
              repo_branch: git_settings[:branch],
              repo_username: git_settings[:username],
              repo_password: git_settings[:password],
              repo_author_name: git_settings[:author_name],
              repo_author_email: git_settings[:author_email]
            )
            run_initializer!("decidim-community_templates.git_mirror")
          end

          it "calls GitCatalogNormalizer" do
            expect(Decidim::CommunityTemplates::GitCatalogNormalizer).to receive(:call)

            run_initializer!("decidim-community_templates.git_mirror")
          end

          it "validates the mirror" do
            expect(mock_mirror).to receive(:validate!)

            run_initializer!("decidim-community_templates.git_mirror")
          end

          it "Decidim::CommunityTemplates.enabled? is true" do
            run_initializer!("decidim-community_templates.git_mirror")
            expect(Decidim::CommunityTemplates.enabled?).to be(true)
          end

          context "when git settings are not defined" do
            before do
              Decidim::CommunityTemplates.configure do |config|
                config.git_settings = {}
              end
            end

            it "does not configure git mirror" do
              expect(Decidim::CommunityTemplates::GitMirror).not_to receive(:instance)
              expect(Decidim::CommunityTemplates::GitCatalogNormalizer).not_to receive(:call)

              # Run the specific initializer
              run_initializer!("decidim-community_templates.git_mirror")
            end

            it "prints a warning message" do
              expect { run_initializer!("decidim-community_templates.git_mirror") }
                .to output(/TEMPLATE_GIT_URL=/).to_stderr
            end

            it "Decidim::CommunityTemplates.enabled? is false" do
              run_initializer!("decidim-community_templates.git_mirror")
              expect(Decidim::CommunityTemplates.enabled?).to be(false)
            end
          end
        end
      end
    end
  end
end
