# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Importers
      RSpec.describe ProcessStep, type: :service do
        let(:organization) { create(:organization, available_locales: [:en, :ca]) }
        let(:user) { create(:user, organization: organization) }
        let(:participatory_process) { create(:participatory_process, organization: organization) }
        let(:parent_object) { OpenStruct.new(object: participatory_process) }

        let(:parser) do
          TemplateParser.new(
            data: {
              "id" => "process_step_id",
              "@class" => "Decidim::ParticipatoryProcessStep",
              "attributes" => {
                "title" => "process_step_id.attributes.title",
                "description" => "process_step_id.attributes.description",
                "start_date_relative" => 86_400, # 1 day in seconds
                "end_date_relative" => 172_800 # 2 days in seconds
              }
            },
            assets: [],
            translations: {
              "en" => {
                "process_step_id" => {
                  "attributes" => {
                    "title" => "Process Step Title",
                    "description" => "Process Step Description"
                  }
                }
              },
              "ca" => {
                "process_step_id" => {
                  "attributes" => {
                    "title" => "Títol del pas del procés",
                    "description" => "Descripció del pas del procés"
                  }
                }
              }
            },
            locales: organization.available_locales.map(&:to_s)
          )
        end

        subject(:importer) { described_class.new(parser, organization, user, parent: parent_object) }

        describe "#import!" do
          context "when all required attributes are present" do
            it "creates a new participatory process step" do
              freeze_time do
                expect { importer.import! }.to change(Decidim::ParticipatoryProcessStep, :count).by(1)
              end
              expect(parent_object.object.steps.count).to eq(1)
            end

            it "sets the correct attributes" do
              freeze_time do
                process_step = importer.import!

                expect(process_step.participatory_process).to eq(participatory_process)
                expect(process_step.title).to eq({
                                                   "en" => "Process Step Title",
                                                   "ca" => "Títol del pas del procés"
                                                 })
                expect(process_step.description).to eq({
                                                         "en" => "Process Step Description",
                                                         "ca" => "Descripció del pas del procés"
                                                       })
                expect(process_step.start_date).to eq(Time.current + 86_400)
                expect(process_step.end_date).to eq(Time.current + 172_800)
              end
            end

            it "returns the created process step" do
              freeze_time do
                process_step = importer.import!
                expect(process_step).to be_a(Decidim::ParticipatoryProcessStep)
                expect(process_step).to be_persisted
              end
            end
          end

          context "when optional dates are nil" do
            let(:parser) do
              TemplateParser.new(
                data: {
                  "id" => "process_step_id",
                  "@class" => "Decidim::ParticipatoryProcessStep",
                  "attributes" => {
                    "title" => "process_step_id.attributes.title",
                    "description" => "process_step_id.attributes.description",
                    "start_date_relative" => nil,
                    "end_date_relative" => nil
                  }
                },
                assets: [],
                translations: {
                  "en" => {
                    "process_step_id" => {
                      "attributes" => {
                        "title" => "Process Step Title",
                        "description" => "Process Step Description"
                      }
                    }
                  }
                },
                locales: organization.available_locales.map(&:to_s)
              )
            end

            it "creates process step with nil dates" do
              process_step = importer.import!
              expect(process_step.start_date).to be_nil
              expect(process_step.end_date).to be_nil
            end
          end
        end

        describe "#from_relative_date" do
          it "converts relative date to absolute date" do
            freeze_time do
              result = importer.send(:from_relative_date, 3600) # 1 hour
              expect(result).to eq(Time.current + 3600)
            end
          end

          it "returns nil for nil input" do
            result = importer.send(:from_relative_date, nil)
            expect(result).to be_nil
          end

          it "returns nil for blank input" do
            result = importer.send(:from_relative_date, "")
            expect(result).to be_nil
          end

          it "handles negative relative dates" do
            freeze_time do
              result = importer.send(:from_relative_date, -3600) # 1 hour ago
              expect(result).to eq(Time.current - 3600)
            end
          end
        end

        describe "inherited behavior" do
          it "has access to parser" do
            expect(importer.parser).to eq(parser)
          end

          it "has access to organization" do
            expect(importer.organization).to eq(organization)
          end

          it "has access to user" do
            expect(importer.user).to eq(user)
          end

          it "has access to parent" do
            expect(importer.parent).to eq(parent_object)
          end

          it "returns organization locales" do
            expect(importer.locales).to eq(%w(en ca))
          end
        end
      end
    end
  end
end
