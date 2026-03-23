# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Importers
      RSpec.describe Post, type: :service do
        let(:organization) { create(:organization, available_locales: [:en, :ca]) }
        let(:user) { create(:user, organization: organization) }
        let(:component) { create(:post_component, organization: organization) }
        let(:parent) { OpenStruct.new(object: component) }
        let(:post) { create(:post, component: component, author: organization) }
        let(:serializer) do
          Serializers::Post.init(
            model: post,
            locales: organization.available_locales,
            metadata: {
              id: SecureRandom.uuid,
              name: { "en" => "Test Post", "ca" => "Post de prova" },
              description: { "en" => "Test description", "ca" => "Descripció de prova" },
              version: "1.0.0",
              author: "Test Author"
            },
            with_manifest: true
          )
        end
        let(:parser) do
          Dir.mktmpdir do |tmpdir|
            serializer.save!(tmpdir)
            template_path = File.join(tmpdir, serializer.id)
            TemplateExtractor.init(template_path: template_path, locales: organization.available_locales).parser
          end
        end

        subject(:importer) { described_class.new(parser, organization, user, parent: parent, for_demo: false) }

        describe "#should_import?" do
          context "when author is organization" do
            it "returns true" do
              expect(importer.send(:should_import?)).to be true
            end
          end

          context "when author is user and not demo" do
            let(:post) { create(:post, component: component, author: create(:user, organization: organization)) }
            let(:serializer) do
              Serializers::Post.init(
                model: post,
                locales: organization.available_locales,
                metadata: {
                  id: SecureRandom.uuid,
                  name: { "en" => "Test Post", "ca" => "Post de prova" },
                  description: { "en" => "Test description", "ca" => "Descripció de prova" },
                  version: "1.0.0",
                  author: "Test Author"
                },
                with_manifest: true
              )
            end
            let(:parser) do
              Dir.mktmpdir do |tmpdir|
                serializer.save!(tmpdir)
                template_path = File.join(tmpdir, serializer.id)
                TemplateExtractor.init(template_path: template_path, locales: organization.available_locales).parser
              end
            end

            it "returns false" do
              expect(importer.send(:should_import?)).to be false
            end
          end

          context "when author is user and demo" do
            let(:post) { create(:post, component: component, author: create(:user, organization: organization)) }
            let(:serializer) do
              Serializers::Post.init(
                model: post,
                locales: organization.available_locales,
                metadata: {
                  id: SecureRandom.uuid,
                  name: { "en" => "Test Post", "ca" => "Post de prova" },
                  description: { "en" => "Test description", "ca" => "Descripció de prova" },
                  version: "1.0.0",
                  author: "Test Author"
                },
                with_manifest: true
              )
            end
            let(:parser) do
              Dir.mktmpdir do |tmpdir|
                serializer.save!(tmpdir)
                template_path = File.join(tmpdir, serializer.id)
                TemplateExtractor.init(template_path: template_path, locales: organization.available_locales).parser
              end
            end
            let(:importer) { described_class.new(parser, organization, user, parent: parent, for_demo: true) }

            it "returns true" do
              expect(importer.send(:should_import?)).to be true
            end
          end
        end

        describe "#import!" do
          context "when author is organization" do
            let!(:imported_post) { importer.import! }

            it "creates a new post" do
              expect(imported_post).to be_persisted
            end

            it "sets the correct title" do
              expect(imported_post.title).to eq(post.title)
            end

            it "sets the correct body" do
              expect(imported_post.body).to eq(post.body)
            end

            it "sets the author to organization" do
              expect(imported_post.author).to eq(organization)
              expect(imported_post.decidim_author_type).to eq("Decidim::Organization")
            end

            it "sets the component" do
              expect(imported_post.component).to eq(component)
            end

            it "sets the correct timestamps" do
              expect(imported_post.created_at).to be_within(1.second).of(post.created_at)
              expect(imported_post.updated_at).to be_within(1.second).of(post.updated_at)
            end
          end

          context "when author is user and not demo" do
            let(:post) { create(:post, component: component, author: create(:user, organization: organization)) }
            let(:serializer) do
              Serializers::Post.init(
                model: post,
                locales: organization.available_locales,
                metadata: {
                  id: SecureRandom.uuid,
                  name: { "en" => "Test Post", "ca" => "Post de prova" },
                  description: { "en" => "Test description", "ca" => "Descripció de prova" },
                  version: "1.0.0",
                  author: "Test Author"
                },
                with_manifest: true
              )
            end
            let(:parser) do
              Dir.mktmpdir do |tmpdir|
                serializer.save!(tmpdir)
                template_path = File.join(tmpdir, serializer.id)
                TemplateExtractor.init(template_path: template_path, locales: organization.available_locales).parser
              end
            end

            it "does not import" do
              expect(importer.import!).to be_nil
            end
          end

          context "when author is user and demo" do
            let(:post) { create(:post, component: component, author: create(:user, organization: organization)) }
            let(:serializer) do
              Serializers::Post.init(
                model: post,
                locales: organization.available_locales,
                metadata: {
                  id: SecureRandom.uuid,
                  name: { "en" => "Test Post", "ca" => "Post de prova" },
                  description: { "en" => "Test description", "ca" => "Descripció de prova" },
                  version: "1.0.0",
                  author: "Test Author"
                },
                with_manifest: true
              )
            end
            let(:parser) do
              Dir.mktmpdir do |tmpdir|
                serializer.save!(tmpdir)
                template_path = File.join(tmpdir, serializer.id)
                TemplateExtractor.init(template_path: template_path, locales: organization.available_locales).parser
              end
            end
            let(:importer) { described_class.new(parser, organization, user, parent: parent, for_demo: true) }
            let!(:imported_post) { importer.import! }

            it "creates a new post" do
              expect(imported_post).to be_persisted
            end

            it "sets the author to a dummy user" do
              expect(imported_post.author).to be_a(Decidim::User)
              expect(imported_post.decidim_author_type).to eq("Decidim::UserBaseEntity")
            end
          end
        end

        describe "#after_import!" do
          context "with attachments" do
            let(:image) do
              Rack::Test::UploadedFile.new(
                Decidim::Dev.test_file("city.jpeg", "image/jpeg"),
                "image/jpeg"
              )
            end
            let!(:attachment) do
              create(:attachment, attached_to: post, file: image)
            end
            let(:serializer) do
              Serializers::Post.init(
                model: post,
                locales: organization.available_locales,
                metadata: {
                  id: SecureRandom.uuid,
                  name: { "en" => "Test Post", "ca" => "Post de prova" },
                  description: { "en" => "Test description", "ca" => "Descripció de prova" },
                  version: "1.0.0",
                  author: "Test Author"
                },
                with_manifest: true
              )
            end
            let(:parser) do
              Dir.mktmpdir do |tmpdir|
                serializer.save!(tmpdir)
                template_path = File.join(tmpdir, serializer.id)
                TemplateExtractor.init(template_path: template_path, locales: organization.available_locales).parser
              end
            end
            let!(:imported_post) { importer.import! }

            before do
              importer.after_import!
            end

            it "imports attachments" do
              expect(imported_post.reload.attachments.count).to eq(1)
            end

            it "sets attachment attributes correctly" do
              imported_attachment = imported_post.reload.attachments.first
              expect(imported_attachment.title).to eq(attachment.title)
              expect(imported_attachment.description).to eq(attachment.description)
              expect(imported_attachment.content_type).to eq(attachment.content_type)
              expect(imported_attachment.file_size).to eq(attachment.file_size)
              expect(imported_attachment.weight).to eq(attachment.weight)
            end

            it "attaches the file" do
              imported_attachment = imported_post.reload.attachments.first
              expect(imported_attachment.file).to be_attached
            end
          end
        end
      end
    end
  end
end

