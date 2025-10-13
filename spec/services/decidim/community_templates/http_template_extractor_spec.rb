# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe HttpTemplateExtractor do
      describe "#locate_asset" do
        let(:catalog_url) { "https://example.com/catalog/00605f97-a5d6-4464-9c7e-5bc5d5840212" }

        it "calls .fetch for each asset" do
          stub_request(:get, "#{catalog_url}/assets.json")
            .to_return(status: 200, body: { assets: [{
              id: "checksum",
              attributes: {
                "@class": "ActiveStorage::Attachment",
                content_type: "image/jpeg",
                name: "hero_image",
                record_type: "Decidim::Component",
                filename: "checksum",
                extension: "jpg"
              }
            }] }.to_json)

          stub_request(:get, "#{catalog_url}/assets/checksum")
            .to_return(status: 200, body: "image_content")
          extractor = described_class.new(template_path: catalog_url, locales: I18n.available_locales)
          allow(HttpTemplateExtractor).to receive(:fetch).and_call_original

          extractor.locate_asset(extractor.assets.first)
          expect(File).to exist(extractor.assets.first["attributes"]["@local_path"])
          expect(HttpTemplateExtractor).to have_received(:fetch).with("#{catalog_url}/assets/checksum")
        end
      end

      describe ".fetch" do
        let(:base_url) { "https://example.com" }
        let(:test_url) { "#{base_url}/test" }

        context "with 200 response" do
          it "returns the response body" do
            stub_request(:get, test_url)
              .to_return(status: 200, body: "test content")

            result = described_class.fetch(test_url)
            expect(result).to eq("test content")
          end

          it "yields to block when given" do
            stub_request(:get, test_url)
              .to_return(status: 200, body: "chunk1chunk2")

            yielded_content = ""
            described_class.fetch(test_url) do |chunk|
              yielded_content += chunk
            end

            expect(yielded_content).to eq("chunk1chunk2")
          end
        end

        context "with redirects" do
          it "follows redirects and returns final content" do
            redirect_url = "#{base_url}/redirect"
            final_url = "#{base_url}/final"

            stub_request(:get, test_url)
              .to_return(status: 301, headers: { "Location" => redirect_url })
            stub_request(:get, redirect_url)
              .to_return(status: 302, headers: { "Location" => final_url })
            stub_request(:get, final_url)
              .to_return(status: 200, body: "final content")

            result = described_class.fetch(test_url)
            expect(result).to eq("final content")
          end

          it "handles relative redirects" do
            stub_request(:get, test_url)
              .to_return(status: 301, headers: { "Location" => "/relative/path" })
            stub_request(:get, "#{base_url}/relative/path")
              .to_return(status: 200, body: "relative redirect content")

            result = described_class.fetch(test_url)
            expect(result).to eq("relative redirect content")
          end

          it "raises error when too many redirects" do
            stub_request(:get, test_url)
              .to_return(status: 301, headers: { "Location" => test_url })

            expect { described_class.fetch(test_url, 1) }
              .to raise_error(ArgumentError, "too many HTTP redirects")
          end
        end

        context "with 400 response" do
          it "returns nil" do
            stub_request(:get, test_url)
              .to_return(status: 400, body: "Bad Request")

            result = described_class.fetch(test_url)
            expect(result).to be_nil
          end
        end

        context "with 404 response" do
          it "returns nil" do
            stub_request(:get, test_url)
              .to_return(status: 404, body: "Not Found")

            result = described_class.fetch(test_url)
            expect(result).to be_nil
          end
        end

        context "with 500 response" do
          it "returns nil" do
            stub_request(:get, test_url)
              .to_return(status: 500, body: "Internal Server Error")

            result = described_class.fetch(test_url)
            expect(result).to be_nil
          end
        end

        context "with other error responses" do
          it "returns nil for 401" do
            stub_request(:get, test_url)
              .to_return(status: 401, body: "Unauthorized")

            result = described_class.fetch(test_url)
            expect(result).to be_nil
          end

          it "returns nil for 403" do
            stub_request(:get, test_url)
              .to_return(status: 403, body: "Forbidden")

            result = described_class.fetch(test_url)
            expect(result).to be_nil
          end
        end

        context "with edge cases" do
          it "raise error if url is malformed" do
            expect { described_class.fetch("hello") }
              .to raise_error(Addressable::URI::InvalidURIError)
          end

          it "return empty string if response body is empty" do
            stub_request(:get, test_url)
              .to_return(status: 200, body: "")

            result = described_class.fetch(test_url)
            expect(result).to eq("")
          end

          it "return nil if http request raise an error" do
            stub_request(:get, test_url)
              .to_raise(StandardError.new("Unexpect error happen"))

            expect(described_class.fetch(test_url))
              .to be_nil
          end

          it "return nil if location header is missing in redirect" do
            stub_request(:get, test_url)
              .to_return(status: 301, headers: {})

            expect(described_class.fetch(test_url))
              .to be_nil
          end

          it "return nil if location header is empty in redirect" do
            stub_request(:get, test_url)
              .to_return(status: 301, headers: { "Location" => "" })

            expect(described_class.fetch(test_url))
              .to be_nil
          end
        end
      end
    end
  end
end
