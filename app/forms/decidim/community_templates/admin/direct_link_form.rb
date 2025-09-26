# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class DirectLinkForm < Decidim::Form
        attribute :link, String

        validates :link, presence: true
        validate :validate_link_secure
        validate :validate_link_ends_with_uuid
        validate :validate_coherence
        validate :validate_manifest_file

        def self.from_params(params)
          strong_params = params.permit(direct_link: [:link])
          new(strong_params[:direct_link])
        end

        def template_id
          @template_id ||= manifest_file["id"]
        end

        def title
          @title ||= manifest_file["title"]
        end

        def short_description
          @short_description ||= manifest_file["short_description"]
        end

        def short_description_html
          @short_description_html ||= markdown_to_html(short_description)
        end

        def version
          @version ||= manifest_file["version"]
        end

        def author
          @author ||= manifest_file["author"]
        end

        def links
          @links ||= manifest_file["links"]
        end

        def has_manifest?
          @manifest_file.present?
        end

        private

        def markdown_to_html(text)
          markdown.render(text).html_safe
        end

        def markdown
          @markdown ||= ::Decidim::Comments::Markdown.new
        end

        def normalized_link
          @normalized_link ||= link.chomp("/")
        end

        ##
        # Fetch a path from the given link
        def fetch_path(path)
          return "" if link_error?

          # standard ruby library calls, no external dependencies
          uri = URI.parse(normalized_link + path)
          response = Net::HTTP.get_response(uri)
          return JSON.parse(response.body) if response.code == "200"

          errors.add(:link, I18n.t("errors.failed_to_fetch", scope: i18n_scope, path: path))
        rescue StandardError => e
          Rails.logger.error("Error fetching path #{path} from #{normalized_link}: #{e.message}")
          errors.add(:link, I18n.t("errors.failed_to_fetch", scope: i18n_scope, path: path))
          return ""
        end

        def i18n_scope
          "decidim.community_templates.admin.direct_link_modal"
        end

        def manifest_file
          @manifest_file ||= fetch_path("/manifest.json")
        end

        def data_file
          @data_file ||= fetch_path("/data.json")
        end

        def folder_name
          @folder_name ||= normalized_link.split("/").last
        end

        def link_error?
          errors.has_key?(:link)
        end

        def validate_link_ends_with_uuid
          return if link.blank? || link_error?

          folder = folder_name
          return if folder.match?(Decidim::CommunityTemplates::Template::UUID_REGEX)

          errors.add(:link, I18n.t("errors.invalid_link", scope: i18n_scope))
        end

        def validate_link_secure
          return if link_error?

          errors.add(:link, I18n.t("errors.invalid_link", scope: i18n_scope)) unless normalized_link.start_with?("https://")
        end

        def validate_coherence
          return if link_error?

          errors.add(:link, I18n.t("errors.invalid_link", scope: i18n_scope)) unless folder_name == template_id
        end

        def validate_manifest_file
          return if link_error?

          errors.add(:link, I18n.t("errors.manifest_file_not_found", scope: i18n_scope)) unless manifest_file
        end
      end
    end
  end
end
