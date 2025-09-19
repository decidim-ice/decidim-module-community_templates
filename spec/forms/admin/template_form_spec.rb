# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Admin
      describe TemplateForm, type: :form do
        class NonExistingParticipatorySpace
          def organization
            nil
          end

          def to_global_id
            "NonExistingParticipatorySpace/1"
          end
        end

        subject { described_class.new(attributes).with_context(**context) }
        let(:participatory_space) { create(:participatory_process) }
        let(:context) do
          {
            current_organization: participatory_space.organization
          }
        end
        let(:attributes) do
          {
            id: participatory_space.to_global_id,
            name:,
            description:,
            version:
          }
        end
        let(:name) { { "ca" => "Nom", "es" => "Nombre", "en" => "Name" } }
        let(:description) { { "ca" => "Descripció", "es" => "Descripción", "en" => "Description" } }
        let(:version) { "1.0.0" }

        it { is_expected.to be_valid }

        context "when name is missing" do
          let(:name) { {} }

          it "defaults to the participatory space title" do
            expect(subject.name).to eq(participatory_space.title)
          end
        end

        context "when description is missing" do
          let(:description) { {} }

          it { is_expected.not_to be_valid }
        end

        context "when version is missing" do
          let(:version) { nil }

          it { is_expected.not_to be_valid }
        end

        context "when participatory space is missing" do
          let(:attributes) { {} }

          it { is_expected.not_to be_valid }
        end

        context "when the organization does not match" do
          let(:other_organization) { create(:organization) }
          let(:context) { { current_organization: other_organization } }

          it { is_expected.not_to be_valid }
        end

        context "when the participatory space is not supported" do
          let(:participatory_space) { NonExistingParticipatorySpace.new }

          it { is_expected.not_to be_valid }
        end
      end
    end
  end
end
