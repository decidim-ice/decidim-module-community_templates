# frozen_string_literal: true

require "spec_helper"
module Decidim
  module CommunityTemplates
    describe CommunityTemplate do
      let(:organization) { create(:organization) }

      context "when updating a community template" do
        let(:template) { create(:community_template) }
        let(:unrelated_process) { create(:participatory_process) }

        it "is valid when updating the title" do
          template.title = "New title"
          expect(template).to be_valid
        end

        it "is invalid when updating the source" do
          template.source = unrelated_process
          expect(template).to be_invalid
          expect(template.errors.full_messages).to include(match(/Source can't be changed/))
        end

        it "is invalid when updating the source_id" do
          template.source_id = unrelated_process.id
          expect(template).to be_invalid
          expect(template.errors.full_messages).to include(match(/Source can't be changed/))
        end

        it "is invalid when updating the source_type" do
          template.source_type = "Decidim::User"
          expect(template).to be_invalid
          expect(template.errors.full_messages).to include(match(/Source can't be changed/))
        end

        it "is invalid when updating the uuid" do
          template.uuid = "123"
          expect(template).to be_invalid
          expect(template.errors.full_messages).to include(match(/Uuid can't be changed/))
        end
      end

      context "when creating a community template" do
        it "has a uuid" do
          template = create(:community_template)
          expect(template.uuid).to be_present
        end

        it "is valid with all attributes present" do
          template = create(:community_template)
          expect(template).to be_valid
        end

        it "is valid without a links_csv" do
          template = build(:community_template, links_csv: nil)
          expect(template).to be_valid
        end

        it "is invalid without an organization" do
          template = build(:community_template, organization: nil)
          expect(template).to be_invalid
        end

        it "is invalid without an author" do
          template = build(:community_template, author: nil)
          expect(template).to be_invalid
        end

        it "is invalid without a title" do
          template = build(:community_template, title: nil)
          expect(template).to be_invalid
        end

        it "is invalid without a short_description" do
          template = build(:community_template, short_description: nil)
          expect(template).to be_invalid
        end

        it "is invalid without a version" do
          template = build(:community_template, version: nil)
          expect(template).to be_invalid
        end

        it "is invalid without a source" do
          template = build(:community_template, source: nil)
          expect(template).to be_invalid
        end

        it "is invalid with a source that is not supported" do
          template = build(:community_template, source: create(:user))
          expect(template).to be_invalid
          expect(template.errors.full_messages).to include(match(/Must be one of: #{Decidim::CommunityTemplates.serializers.first[:model]}/))
        end

        it "is invalid with a source that does not exists" do
          template = build(:community_template, source_id: 0, source_type: "Decidim::ParticipatoryProcess")
          expect(template).to be_invalid
          expect(template.errors.full_messages).to include(match(/Source must exist/))
        end

        it "is invalid with a duplicated source" do
          template = create(:community_template, organization:)
          template2 = build(:community_template, source: template.source, organization:)
          expect(template2).to be_invalid
          expect(template2.errors.full_messages).to include(match(/Source has already been taken/))
        end
      end
    end
  end
end
