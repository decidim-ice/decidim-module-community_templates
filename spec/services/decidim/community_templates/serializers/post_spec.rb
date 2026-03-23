# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Serializers
      describe Post do
        let(:organization) { create(:organization, available_locales: [:en, :ca]) }
        let(:component) { create(:post_component, organization: organization) }
        let(:author) { create(:user, organization: organization) }
        let(:post) { create(:post, component: component, author: author) }
        let(:serializer) { described_class.init(model: post, locales: organization.available_locales) }
        let(:data) { serializer.data }
        let(:attributes) { data[:attributes] }
        let(:assets) { serializer.assets }

        describe "#attributes" do
          it "includes title" do
            expect(attributes[:title]).to eq("#{serializer.id}.attributes.title")
          end

          it "includes body" do
            expect(attributes[:body]).to eq("#{serializer.id}.attributes.body")
          end

          it "includes created_at_relative" do
            freeze_time do
              expect(attributes[:created_at_relative]).to eq(post.created_at.to_time.to_i - Time.zone.now.to_i)
            end
          end

          it "includes updated_at_relative" do
            freeze_time do
              expect(attributes[:updated_at_relative]).to eq(post.updated_at.to_time.to_i - Time.zone.now.to_i)
            end
          end

          it "includes published_at_relative" do
            freeze_time do
              post.update!(published_at: 1.hour.ago)
              expect(attributes[:published_at_relative]).to eq(post.published_at.to_time.to_i - Time.zone.now.to_i)
            end
          end

          it "includes deleted_at_relative" do
            freeze_time do
              post.update!(deleted_at: 1.hour.ago)
              expect(attributes[:deleted_at_relative]).to eq(post.deleted_at.to_time.to_i - Time.zone.now.to_i)
            end
          end

          context "when author is organization" do
            let(:post) { create(:post, component: component, author: organization) }

            it "includes decidim_author_type as organization" do
              expect(attributes[:decidim_author_type]).to eq("organization")
            end
          end

          context "when author is user" do
            it "includes decidim_author_type as nil" do
              expect(attributes[:decidim_author_type]).to be_nil
            end
          end

          context "when author is user group" do
            let(:user_group) { create(:user_group, organization: organization) }
            let(:post) { create(:post, component: component, author: user_group) }

            it "includes decidim_author_type as nil" do
              expect(attributes[:decidim_author_type]).to be_nil
            end
          end
        end

        describe "#attachments" do
          context "when post has no attachments" do
            it "returns an empty array" do
              expect(attributes[:attachments]).to eq([])
            end
          end

          context "when post has attachments" do
            let(:image) do
              Rack::Test::UploadedFile.new(
                Decidim::Dev.test_file("city.jpeg", "image/jpeg"),
                "image/jpeg"
              )
            end
            let!(:attachment) do
              create(:attachment, attached_to: post, file: image)
            end

            it "includes attachments" do
              expect(attributes[:attachments]).to be_an(Array)
              expect(attributes[:attachments].size).to eq(1)
            end

            it "serializes attachment attributes" do
              attachment_data = attributes[:attachments].first
              expect(attachment_data[:title]).to be_a(String)
              expect(attachment_data[:description]).to be_a(String)
              expect(attachment_data[:content_type]).to eq(attachment.content_type)
              expect(attachment_data[:file_size]).to eq(attachment.file_size)
              expect(attachment_data[:weight]).to eq(attachment.weight)
              expect(attachment_data[:file]).to be_a(String)
            end

            it "includes attachment file in assets" do
              expect(assets.map(&:model)).to include(attachment.file.attachment)
            end
          end

          context "when attachment has no file" do
            let!(:attachment) do
              create(:attachment, attached_to: post, file: nil)
            end

            it "excludes attachments without files" do
              expect(attributes[:attachments]).to eq([])
            end
          end
        end

        describe "translations" do
          it "generates translations for title" do
            expect(serializer.translations["en"][serializer.id]["attributes"]["title"]).to eq(post.title["en"])
            expect(serializer.translations["ca"][serializer.id]["attributes"]["title"]).to eq(post.title["ca"])
          end

          it "generates translations for body" do
            expect(serializer.translations["en"][serializer.id]["attributes"]["body"]).to eq(post.body["en"])
            expect(serializer.translations["ca"][serializer.id]["attributes"]["body"]).to eq(post.body["ca"])
          end

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

            it "generates translations for attachment title and description" do
              attachment_id = SerializerBase.id_for_model(attachment)
              expect(serializer.translations["en"][serializer.id]["attributes"]["attachments"][attachment_id]["title"]).to eq(attachment.title["en"])
              expect(serializer.translations["en"][serializer.id]["attributes"]["attachments"][attachment_id]["description"]).to eq(attachment.description["en"])
            end
          end
        end

        describe "#save!" do
          it "saves the serialized json data to disk" do
            Dir.mktmpdir do |dir|
              serializer.save!(dir)
              base_path = File.join(dir, serializer.id)
              expect(File).to exist(File.join(base_path, "data.json"))
            end
          end

          it "saves translations to disk" do
            Dir.mktmpdir do |dir|
              serializer.save!(dir)
              base_path = File.join(dir, serializer.id)
              expect(File).to exist(File.join(base_path, "locales", "en.yml"))
              expect(File).to exist(File.join(base_path, "locales", "ca.yml"))
            end
          end

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

            it "saves attachment assets to disk" do
              Dir.mktmpdir do |dir|
                serializer.save!(dir)
                base_path = File.join(dir, serializer.id)
                filename = Serializers::Attachment.filename(attachment.file.attachment)
                expect(File).to exist(File.join(base_path, "assets", filename))
              end
            end
          end
        end
      end
    end
  end
end

