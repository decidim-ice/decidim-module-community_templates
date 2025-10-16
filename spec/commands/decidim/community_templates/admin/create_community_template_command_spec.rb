# frozen_string_literal: true

require "spec_helper"

module Decidim::CommunityTemplates::Admin
  describe CreateCommunityTemplateCommand do
    let(:organization) { create(:organization) }
    let(:user) { create(:user, :confirmed, :admin, organization:) }
    let(:template) { build(:template_metadata, organization:) }
    let(:template_source) { build(:community_template_source, organization:) }
    let!(:git_settings) { create(:git_settings) }
    let(:catalog_path) { Rails.root.join("tmp", "catalog", "test_#{SecureRandom.hex(4)}") }
    let(:git) { create(:git, :with_commit, path: catalog_path) }
    let(:git_mirror) { create(:git_mirror, catalog_path: catalog_path) }
    let(:form) do
      Decidim::CommunityTemplates::Admin::TemplateSourceForm.new(
        source_id: template_source&.source ? template_source.source.to_global_id.to_s : nil,
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
      allow(serializer).to receive(:save!).and_call_original
      allow(serializer).to receive(:metadata_translations!).and_call_original
      serializer
    end

    before do
      allow(Decidim::CommunityTemplates::GitMirror).to receive(:instance).and_return(git_mirror)
      allow(Decidim::CommunityTemplates).to receive(:catalog_path).and_return(catalog_path)

      Decidim::CommunityTemplates::TemplateSource.destroy_all
      allow(Decidim::CommunityTemplates::GitTransaction).to receive(:perform).and_yield(git)

      Decidim::CommunityTemplates::GitMirror.instance.configure(
        git_settings.attributes
      )
    end

    it "creates a new template source" do
      expect { CreateCommunityTemplateCommand.call(form, organization) }.to change(Decidim::CommunityTemplates::TemplateSource, :count).by(1)
    end

    context "when the form is invalid" do
      before do
        allow(form).to receive(:invalid?).and_return(true)
      end

      it "does not create a new template source" do
        expect { CreateCommunityTemplateCommand.call(form, organization) }.not_to change(Decidim::CommunityTemplates::TemplateSource, :count)
      end

      it "do not save the template file" do
        CreateCommunityTemplateCommand.call(form, organization)
        expect(serializer).not_to have_received(:save!)
      end
    end

    context "when the template files fails to be written" do
      it "does not create template model" do
        allow(serializer).to receive(:save!).and_raise(Errno::ENOENT)

        expect { CreateCommunityTemplateCommand.call(form, organization) }.not_to change(Decidim::CommunityTemplates::TemplateSource, :count)
        expect(form.errors[:base]).to include(match(/No such file or directory/))
      end

      it "call template#delete" do
        allow(serializer).to receive(:save!).and_raise(Errno::ENOSPC)
        allow(form.template).to receive(:delete).and_call_original

        CreateCommunityTemplateCommand.call(form, organization)
        expect(form.template).to have_received(:delete).with(Decidim::CommunityTemplates.catalog_path)
        expect(form.errors[:base]).to include(match(/No space/))
      end

      it "log the errors" do
        allow(serializer).to receive(:save!).and_raise(Errno::EACCES)
        allow(Rails.logger).to receive(:error).and_call_original

        CreateCommunityTemplateCommand.call(form, organization)
        expect(Rails.logger).to have_received(:error).with(/Permission denied/).at_least(:once)
      end

      it "adds an error to the form" do
        allow(serializer).to receive(:save!).and_raise(Errno::ENAMETOOLONG)

        CreateCommunityTemplateCommand.call(form, organization)
        expect(form.errors).to have_key(:base)
        expect(form.errors[:base]).to include(match(/File name too long/))
      end

      it "broadcasts :invalid" do
        allow(serializer).to receive(:save!).and_raise(Errno::EROFS)

        result = CreateCommunityTemplateCommand.call(form, organization)
        expect(result).to have_key(:invalid)
        expect(form.errors[:base]).to include(match(/Git operation failed: Read-only file system/))
      end
    end
  end
end
