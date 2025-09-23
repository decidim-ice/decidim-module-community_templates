# frozen_string_literal: true

require "spec_helper"

module Decidim::CommunityTemplates::Admin
  describe CreateCommunityTemplateCommand do
    let(:organization) { create(:organization) }
    let(:user) { create(:user, :confirmed, :admin, organization:) }
    let(:template) { build(:template) }
    let(:template_source) { build(:community_template_source, organization:) }
    let(:form) do
      Decidim::CommunityTemplates::Admin::TemplateSourceForm.new(
        source_id: template_source&.source ? template_source.source.to_global_id.to_s : nil,
        template: template
      )
    end

    it "creates a new template source" do
      expect { CreateCommunityTemplateCommand.call(form, organization) }.to change(Decidim::CommunityTemplates::TemplateSource, :count).by(1)
    end

    context "when the form is invalid" do
      let(:template_source) { build(:community_template_source, organization:, source_id: nil) }

      it "does not create a new template source" do
        expect { CreateCommunityTemplateCommand.call(form, organization) }.not_to change(Decidim::CommunityTemplates::TemplateSource, :count)
      end

      it "do not save the template file" do
        # Should not create any directory in the catalog path
        expect do
          CreateCommunityTemplateCommand.call(form, organization)
        end.not_to change(Decidim::CommunityTemplates.catalog_path.children, :size)
      end
    end

    context "when the template files fails to be written" do
      it "does not create template model" do
        allow(form.template).to receive(:write).and_raise(Errno::ENOENT)

        expect { CreateCommunityTemplateCommand.call(form, organization) }.not_to change(Decidim::CommunityTemplates::TemplateSource, :count)
        expect(form.errors[:base]).to include(match(/File not found/))
      end

      it "call template#delete" do
        allow(form.template).to receive(:write).and_raise(Errno::ENOSPC)
        allow(form.template).to receive(:delete).and_call_original

        CreateCommunityTemplateCommand.call(form, organization)
        expect(form.template).to have_received(:delete)
        expect(form.errors[:base]).to include(match(/No space/))
      end

      it "log the errors" do
        allow(form.template).to receive(:write).and_raise(Errno::EACCES)
        allow(Rails.logger).to receive(:error).and_call_original

        CreateCommunityTemplateCommand.call(form, organization)
        expect(Rails.logger).to have_received(:error).with(/Permission denied/)
      end

      it "adds an error to the form" do
        allow(form.template).to receive(:write).and_raise(Errno::ENAMETOOLONG)

        CreateCommunityTemplateCommand.call(form, organization)
        expect(form.errors).to have_key(:base)
        expect(form.errors[:base]).to include(match(/File name too long/))
      end

      it "broadcasts :invalid" do
        allow(form.template).to receive(:write).and_raise(Errno::EROFS)

        result = CreateCommunityTemplateCommand.call(form, organization)
        expect(result).to have_key(:invalid)
        expect(form.errors[:base]).to include(match(/Catalog directory is read only/))
      end
    end
  end
end
