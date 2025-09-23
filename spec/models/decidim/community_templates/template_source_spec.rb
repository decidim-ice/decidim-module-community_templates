# frozen_string_literal: true

require "spec_helper"
module Decidim
  module CommunityTemplates
    describe TemplateSource do
      let(:organization) { create(:organization) }

      context "when updating a community template source" do
        let(:template_source) { create(:community_template_source) }
        let(:unrelated_process) { create(:participatory_process) }

        it "is invalid when updating the source" do
          template_source.source = unrelated_process
          expect(template_source).to be_invalid
          expect(template_source.errors.full_messages).to include(match(/can't be changed/))
        end

        it "is invalid when updating the source_id" do
          template_source.source_id = unrelated_process.id
          expect(template_source).to be_invalid
          expect(template_source.errors.full_messages).to include(match(/can't be changed/))
        end

        it "is invalid when updating the source_type" do
          template_source.source_type = "Decidim::User"
          expect(template_source).to be_invalid
          expect(template_source.errors.full_messages).to include(match(/can't be changed/))
        end
      end

      context "when creating a community template source" do
        it "is invalid if the template_id is not a valid UUID" do
          template_source = build(:community_template_source, template_id: "invalid_id")
          expect(template_source).to be_invalid
          expect(template_source.errors.full_messages).to include(match(/Template is not a valid UUID/))
        end

        it "is invalid if the template_id is nil" do
          template_source = build(:community_template_source, template_id: nil)
          expect(template_source).to be_invalid
          expect(template_source.errors.full_messages).to include(match(/Template cannot be blank/))
        end

        it "is unique" do
          template_source = create(:community_template_source)
          template_source2 = build(:community_template_source, template_id: template_source.template_id)
          expect(template_source2).to be_invalid
          expect(template_source2.errors.full_messages).to include(match(/has already been taken/))
        end

        it "is valid with all attributes present" do
          template_source = create(:community_template_source)
          expect(template_source).to be_valid
        end

        it "is invalid without an organization" do
          template_source = build(:community_template_source, organization: nil)
          expect(template_source).to be_invalid
        end

        it "is invalid without a source" do
          template_source = build(:community_template_source, source: nil)
          expect(template_source).to be_invalid
        end

        it "is invalid with a source that is not supported" do
          template_source = build(:community_template_source, source: create(:user))
          expect(template_source).to be_invalid
          expect(template_source.errors.full_messages).to include(match(/Must be one of: #{Decidim::CommunityTemplates.serializers.first[:model]}/))
        end

        it "is invalid with a source that does not exists" do
          template_source = build(:community_template_source, source_id: 0, source_type: "Decidim::ParticipatoryProcess")
          expect(template_source).to be_invalid
          expect(template_source.errors.full_messages).to include(match(/must exist/))
        end

        it "is invalid with a duplicated source" do
          template_source = create(:community_template_source, organization:)
          template_source2 = build(:community_template_source, source: template_source.source, organization:)
          expect(template_source2).to be_invalid
          expect(template_source2.errors.full_messages).to include(match(/has already been taken/))
        end

        it "is invalid with a record that does not belongs to the same organization" do
          template_source = build(:community_template_source, source: create(:participatory_process, organization: create(:organization)), organization: create(:organization))
          expect(template_source).to be_invalid
          expect(template_source.errors.full_messages).to include(match(/must be in the same organization as/))
        end
      end
    end
  end
end
