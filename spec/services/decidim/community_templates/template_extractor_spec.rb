# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe TemplateExtractor do
      let(:template_path) { "spec/fixtures/template_test/valid" }
      let(:locales) { [:en, :"pt-BR"] }
      let(:extractor) { described_class.new(template_path: template_path, locales: locales) }

      describe "#invalid?" do
        context "when template path is missing" do
          let(:extractor) { described_class.new(template_path: nil, locales: locales) }

          it "is invalid" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:template_path]).to include("cannot be blank")
          end
        end

        context "when template path does not exist" do
          let(:template_path) { "spec/fixtures/template_test/nonexistent" }

          it "is invalid" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:base]).to include(I18n.t("template_path_not_found", scope: extractor.i18n_scope))
          end
        end

        context "when locales are invalid" do
          let(:locales) { %w(invalid_locale another_invalid) }

          it "is invalid" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:locales]).to include("is not included in the list")
          end
        end

        context "when data.json is malformed" do
          let(:template_path) { "spec/fixtures/template_test/malformatted" }

          it "is invalid due to JSON parsing error" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:base]).to include(/Unknown error:/)
          end
        end

        context "when no space left on device (ENOSPC)" do
          before do
            allow(File).to receive(:read).and_raise(Errno::ENOSPC)
          end

          it "is invalid due to no space" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:base]).to include(I18n.t("no_space", scope: extractor.i18n_scope))
          end
        end

        context "when permission denied (EACCES)" do
          before do
            allow(File).to receive(:read).and_raise(Errno::EACCES)
          end

          it "is invalid due to permission denied" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:base]).to include(I18n.t("permission_denied", scope: extractor.i18n_scope))
          end
        end

        context "when file name too long (ENAMETOOLONG)" do
          before do
            allow(File).to receive(:read).and_raise(Errno::ENAMETOOLONG)
          end

          it "is invalid due to name too long" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:base]).to include(I18n.t("name_too_long", scope: extractor.i18n_scope))
          end
        end

        context "when read-only filesystem (EROFS)" do
          before do
            allow(File).to receive(:read).and_raise(Errno::EROFS)
          end

          it "is invalid due to read-only filesystem" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:base]).to include(I18n.t("read_only_filesystem", scope: extractor.i18n_scope))
          end
        end

        context "when unknown file system error occurs" do
          before do
            allow(File).to receive(:read).and_raise(StandardError.new("Unknown error"))
          end

          it "is invalid due to unknown error" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:base]).to include(I18n.t("unknown", scope: extractor.i18n_scope))
          end
        end

        context "when data.json contains invalid template metadata" do
          let(:template_path) { "spec/fixtures/template_test/invalid_id" }

          it "is invalid due to invalid UUID in template metadata" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:base]).to include(/Malformed data: Id is invalid/)
          end
        end

        context "when data.json file is missing" do
          let(:template_path) { "spec/fixtures/template_test/missing_data" }

          before do
            # Create a directory without data.json
            FileUtils.mkdir_p(template_path)
          end

          after do
            FileUtils.rm_rf(template_path)
          end

          it "is invalid due to file not found" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:base]).to include(I18n.t("file_not_found", scope: extractor.i18n_scope))
          end
        end

        context "when data.json is empty" do
          let(:template_path) { "spec/fixtures/template_test/empty_data" }

          before do
            FileUtils.mkdir_p(template_path)
            File.write(File.join(template_path, "data.json"), "")
          end

          after do
            FileUtils.rm_rf(template_path)
          end

          it "is invalid due to empty JSON" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:base]).to include(/Unknown error:/)
          end
        end

        context "when data.json contains valid structure but invalid metadata" do
          let(:template_path) { "spec/fixtures/template_test/invalid_metadata" }

          before do
            FileUtils.mkdir_p(template_path)
            File.write(File.join(template_path, "data.json"), {
              "id" => "invalid_id",
              "@class" => "Decidim::ParticipatoryProcess",
              "name" => "test.metadata.name",
              "description" => "test.metadata.description",
              "version" => "1.0.0",
              "decidim_version" => "0.30.1",
              "community_templates_version" => "0.0.1",
              "attributes" => {
                "title" => "test.attributes.title",
                "description" => "test.attributes.description"
              }
            }.to_json)
          end

          after do
            FileUtils.rm_rf(template_path)
          end

          it "is invalid due to invalid UUID format" do
            expect(extractor).to be_invalid
            expect(extractor.errors[:base]).to include(/Malformed data: Id is invalid/)
          end
        end

        describe "#assets" do
          it "add @local_path to each asset" do
            expect(extractor.assets.size).to eq(1)
            local_path = extractor.assets.first["attributes"]["@local_path"]
            expect(local_path).to eq(File.join(template_path, "assets", extractor.assets.first["id"]))
          end

          it "calls locate_asset for each asset" do
            allow(extractor).to receive(:locate_asset).and_call_original
            extractor.assets
            expect(extractor).to have_received(:locate_asset).with(extractor.assets.first)
          end
        end

        context "when template is valid" do
          let(:template_path) { "spec/fixtures/template_test/valid" }

          it "is valid" do
            expect(extractor).to be_valid
          end
        end
      end
    end
  end
end
