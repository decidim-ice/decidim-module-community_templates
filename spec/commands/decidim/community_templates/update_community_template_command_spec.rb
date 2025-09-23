# frozen_string_literal: true

require "spec_helper"

module Decidim::CommunityTemplates::Admin
  describe UpdateCommunityTemplateCommand do
    let(:organization) { create(:organization) }
    let(:user) { create(:user, :confirmed, :admin, organization:) }
    let(:template) { build(:template) }
    let(:template_source) { create(:community_template_source, organization:) }
    let(:form) do
      Decidim::CommunityTemplates::Admin::TemplateSourceForm.new(
        source_id: template_source.source.to_global_id.to_s,
        template: template
      )
    end

    it "updates the template" do
      expect { UpdateCommunityTemplateCommand.call(form) }.to change(Decidim::CommunityTemplates::TemplateSource, :count).by(1)
    end

    context "when the form is invalid" do
      before do
        allow(form).to receive(:invalid?).and_return(true)
        allow(form.template).to receive(:write).and_call_original
      end

      it "does not update the template" do
        UpdateCommunityTemplateCommand.call(form)
        expect(form.template).not_to have_received(:write)
      end

      it "broadcasts :invalid" do
        result = UpdateCommunityTemplateCommand.call(form)
        expect(result).to have_key(:invalid)
      end
    end

    context "when the template files fails to be written" do
      [Errno::ENOENT, Errno::ENOSPC, Errno::EACCES, Errno::ENAMETOOLONG, Errno::EROFS].each do |error|
        it "Handle #{error}" do
          allow(form.template).to receive(:write).and_raise(error)
          UpdateCommunityTemplateCommand.call(form)
          expect(form.errors).to have_key(:base)
          expect(form.errors[:base]).to include(match(/Server error/))
        end
      end
    end
  end
end
