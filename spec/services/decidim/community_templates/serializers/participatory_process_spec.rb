# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Serializers
      describe ParticipatoryProcess do
        let(:participatory_process) { create(:participatory_process, :with_steps) }
        let(:serializer) { described_class.new(participatory_process) }
        let(:serialized_data) { serializer.serialize }
        let(:data) { serialized_data[:data] }
        let(:demo) { serialized_data[:demo] }
        let(:assets) { serializer.assets }

        it "generates a unique id" do
          expect(serializer.id).to match(/\A[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}\z/)
        end

        it "has the correct type" do
          expect(data[:class]).to eq("Decidim::ParticipatoryProcess")
          expect(data[:id]).to eq(serializer.id)
          expect(data[:title]).to eq("#{serializer.id}.title")
          expect(data[:description]).to eq("#{serializer.id}.description")
        end

        it "generates translations" do
          serializer.serialize
          ca = serializer.translations["ca"][serializer.id]
          en = serializer.translations["en"][serializer.id]
          expect(ca["title"]).to eq(participatory_process.title["ca"])
          expect(en["title"]).to eq(participatory_process.title["en"])
          expect(ca["description"]).to eq(participatory_process.description["ca"])
          expect(en["description"]).to eq(participatory_process.description["en"])
        end
      end
    end
  end
end
