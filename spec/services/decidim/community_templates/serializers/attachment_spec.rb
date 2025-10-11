# frozen_string_literal: true

require "spec_helper"
module Decidim
  module CommunityTemplates
    module Serializers
      describe Attachment do
        let(:model) { create(:attachment).file.attachment }
        let(:serializer) { described_class.init(model:) }

        describe "#filename" do
          it "calls the class method with the model" do
            allow(described_class).to receive(:filename).with(model).and_return("test-pdf")
            expect(serializer.filename).to eq("test-pdf")
          end
        end

        describe "Class#filename" do
          it "strip spaces" do
            allow(model.blob).to receive(:checksum).and_return("  test  pdf  ")
            expect(described_class.filename(model)).not_to include(" ")
          end

          it "encode into a parameterized base64" do
            ["special+pdf", "special pdf?", "special pdf&", "special pdf(", "special pdf)", "special pdf*", "special pdf/", "special pdf@", "special pdf 👋"].each do |filename|
              allow(model.blob).to receive(:checksum).and_return(filename)
              expect(described_class.filename(model)).to eq(Base64.urlsafe_encode64(filename).parameterize)
            end
          end
        end
      end
    end
  end
end
