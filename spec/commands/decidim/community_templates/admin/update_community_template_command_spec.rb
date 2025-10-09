# frozen_string_literal: true

require "spec_helper"

module Decidim::CommunityTemplates::Admin
  describe UpdateCommunityTemplateCommand do
    let!(:organization) { create(:organization) }
    let!(:user) { create(:user, :confirmed, :admin, organization:) }
    let!(:template) { build(:template_metadata) }
    let!(:template_source) { create(:community_template_source, organization:) }
    let!(:form) do
      Decidim::CommunityTemplates::Admin::TemplateSourceForm.new(
        source_id: template_source.source.to_global_id.to_s,
        template: template
      )
    end

    let!(:serializer) do
      serializer = Decidim::CommunityTemplates::Serializers::ParticipatoryProcess.init(
        model: template_source.source,
        locales: [organization.default_locale],
        with_manifest: true,
        metadata: template.as_json
      )
      allow(Decidim::CommunityTemplates::Serializers::ParticipatoryProcess).to receive(:init).and_return(serializer)
      allow(serializer).to receive(:save!)
      serializer
    end

    it "updates the template" do
      UpdateCommunityTemplateCommand.call(form, organization)
      expect(serializer).to have_received(:save!)
    end

    context "when the form is invalid" do
      before do
        allow(form).to receive(:invalid?).and_return(true)
      end

      it "does not update the template" do
        UpdateCommunityTemplateCommand.call(form, organization)
        expect(serializer).not_to have_received(:save!)
      end

      it "broadcasts :invalid" do
        result = UpdateCommunityTemplateCommand.call(form, organization)
        expect(result).to have_key(:invalid)
      end
    end

    context "when the template files fails to be written" do
      [Errno::ENOENT, Errno::ENOSPC, Errno::EACCES, Errno::ENAMETOOLONG, Errno::EROFS].each do |error|
        it "Handle #{error}" do
          allow(serializer).to receive(:save!).and_raise(error)
          UpdateCommunityTemplateCommand.call(form, organization)
          expect(form.errors).to have_key(:base)
          expect(form.errors[:base]).to include(match(/Server error/))
        end
      end
    end
  end
end
