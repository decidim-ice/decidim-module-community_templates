# frozen_string_literal: true

require "spec_helper"
module Decidim
  module CommunityTemplates
    describe TemplateUse do
      let(:organization) { create(:organization) }

      context "when updating a community template use" do
        let(:template_use) { create(:community_template_use) }
        let(:unrelated_process) { create(:participatory_process) }

        it "is invalid when updating the resource" do
          template_use.resource = unrelated_process
          expect(template_use).to be_invalid
          expect(template_use.errors.full_messages).to include(match(/can't be changed/))
        end

        it "is invalid when updating the resource_id" do
          template_use.resource_id = unrelated_process.id
          expect(template_use).to be_invalid
          expect(template_use.errors.full_messages).to include(match(/can't be changed/))
        end

        it "is invalid when updating the resource_type" do
          template_use.resource_type = "Decidim::User"
          expect(template_use).to be_invalid
          expect(template_use.errors.full_messages).to include(match(/can't be changed/))
        end
      end

      context "when creating a community template use" do
        it "is invalid if the template_id is not a valid UUID" do
          template_use = build(:community_template_use, template_id: "invalid_id")
          expect(template_use).to be_invalid
          expect(template_use.errors.full_messages).to include(match(/Template is not a valid UUID/))
        end

        it "is invalid if the template_id is nil" do
          template_use = build(:community_template_use, template_id: nil)
          expect(template_use).to be_invalid
          expect(template_use.errors.full_messages).to include(match(/Template cannot be blank/))
        end

        it "is unique" do
          template_use = create(:community_template_use)
          template_use2 = build(:community_template_use, template_id: template_use.template_id)
          expect(template_use2).to be_invalid
          expect(template_use2.errors.full_messages).to include(match(/has already been taken/))
        end

        it "is valid with all attributes present" do
          template_use = create(:community_template_use)
          expect(template_use).to be_valid
        end

        it "is invalid without an organization" do
          template_use = build(:community_template_use, organization: nil)
          expect(template_use).to be_invalid
          expect(template_use.errors.full_messages).to include(match(/must exist/))
        end

        it "is invalid without a resource" do
          template_use = build(:community_template_use, resource: nil)
          expect(template_use).to be_invalid
          expect(template_use.errors.full_messages).to include(match(/must exist/))
        end

        it "is invalid with a resource that is not supported" do
          template_use = build(:community_template_use, resource: create(:user))
          expect(template_use).to be_invalid
          expect(template_use.errors.full_messages).to include(match(/Must be one of: #{Decidim::CommunityTemplates.serializers.first[:model]}/))
        end

        it "is invalid with a resource that does not exists" do
          template_use = build(:community_template_use, resource_id: 0, resource_type: "Decidim::ParticipatoryProcess")
          expect(template_use).to be_invalid
          expect(template_use.errors.full_messages).to include(match(/must exist/))
        end

        it "is invalid with a duplicated resource" do
          template_use = create(:community_template_use, organization:)
          template_use2 = build(:community_template_use, resource: template_use.resource, organization:)
          expect(template_use2).to be_invalid
          expect(template_use2.errors.full_messages).to include(match(/has already been taken/))
        end

        it "is invalid with a record that does not belongs to the same organization" do
          template_use = build(:community_template_use, resource: create(:participatory_process, organization: create(:organization)), organization: create(:organization))
          expect(template_use).to be_invalid
          expect(template_use.errors.full_messages).to include(match(/must be in the same organization/))
        end
      end
    end
  end
end
