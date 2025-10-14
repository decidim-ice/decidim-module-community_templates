# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Serializers
      describe ProcessStep do
        let(:model) { create(:participatory_process_step, start_date: 2.months.from_now, end_date: 3.months.from_now) }
        let(:serializer) { described_class.init(model:) }
        let(:data) { serializer.data }
        let(:attributes) { data[:attributes] }

        describe "#attributes" do
          it "includes title" do
            expect(attributes[:title]).to eq("#{serializer.id}.attributes.title")
          end

          it "includes description" do
            expect(attributes[:description]).to eq("#{serializer.id}.attributes.description")
          end

          it "includes start_date_relative" do
            freeze_time do
              expected_relative = Time.current.to_i - model.start_date.to_i
              expect(attributes[:start_date_relative]).to eq(expected_relative)
            end
          end

          it "includes end_date_relative" do
            freeze_time do
              expected_relative = Time.current.to_i - model.end_date.to_i
              expect(attributes[:end_date_relative]).to eq(expected_relative)
            end
          end
        end

        describe "with nil dates" do
          let(:model) { create(:participatory_process_step, start_date: nil, end_date: nil) }

          it "handles nil start_date" do
            expect(attributes[:start_date_relative]).to be_nil
          end

          it "handles nil end_date" do
            expect(attributes[:end_date_relative]).to be_nil
          end
        end

        describe "with future dates" do
          let(:model) { create(:participatory_process_step, start_date: 1.month.from_now, end_date: 2.months.from_now) }

          it "calculates negative start_date_relative for future dates" do
            freeze_time do
              expected_relative = Time.current.to_i - model.start_date.to_i
              expect(attributes[:start_date_relative]).to eq(expected_relative)
              expect(attributes[:start_date_relative]).to be < 0
            end
          end

          it "calculates negative end_date_relative for future dates" do
            freeze_time do
              expected_relative = Time.current.to_i - model.end_date.to_i
              expect(attributes[:end_date_relative]).to eq(expected_relative)
              expect(attributes[:end_date_relative]).to be < 0
            end
          end
        end

        describe "with past dates" do
          let(:model) { create(:participatory_process_step, start_date: 2.months.ago, end_date: 1.month.ago) }

          it "calculates positive start_date_relative for past dates" do
            freeze_time do
              expected_relative = Time.current.to_i - model.start_date.to_i
              expect(attributes[:start_date_relative]).to eq(expected_relative)
              expect(attributes[:start_date_relative]).to be > 0
            end
          end

          it "calculates positive end_date_relative for past dates" do
            freeze_time do
              expected_relative = Time.current.to_i - model.end_date.to_i
              expect(attributes[:end_date_relative]).to eq(expected_relative)
              expect(attributes[:end_date_relative]).to be > 0
            end
          end
        end

        describe "translations" do
          let(:locales) { %w(en ca) }
          let(:serializer) { described_class.init(model:, locales:) }

          it "generates translations for title" do
            expect(serializer.translations["en"][serializer.id]["attributes"]["title"]).to eq(model.title["en"])
            expect(serializer.translations["ca"][serializer.id]["attributes"]["title"]).to eq(model.title["ca"])
          end

          it "generates translations for description" do
            expect(serializer.translations["en"][serializer.id]["attributes"]["description"]).to eq(model.description["en"])
            expect(serializer.translations["ca"][serializer.id]["attributes"]["description"]).to eq(model.description["ca"])
          end
        end

        describe "data structure" do
          it "has correct metadata" do
            expect(data[:id]).to eq(serializer.id)
            expect(data[:@class]).to eq("Decidim::ParticipatoryProcessStep")
            expect(data[:attributes]).to eq(attributes)
          end

          it "has correct attributes structure" do
            expect(attributes).to be_a(Hash)
            expect(attributes.keys).to contain_exactly(:title, :description, :start_date_relative, :end_date_relative)
          end
        end
      end
    end
  end
end
