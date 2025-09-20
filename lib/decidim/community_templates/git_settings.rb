module Decidim
  module CommunityTemplates
    class GitSettings
      include ActiveModel::Model
      include Decidim::AttributeObject::Model

      attribute :repo_url, String
      attribute :repo_branch, String
      attribute :repo_username, String
      attribute :repo_password, String
      attribute :repo_author_name, String
      attribute :repo_author_email, String

      validates :repo_url, presence: true
      validates :repo_branch, presence: true
      validates :repo_password, presence: true, if: -> { repo_username.present? }
      validates :repo_username, presence: true, if: -> { repo_password.present? }
      validates :repo_author_name, presence: true, length: { minimum: 3 }
      validates :repo_author_email, presence: true

      validate :repo_url_is_valid
      validate :author_email_is_valid

      def repo_url_is_valid
        return if repo_url.blank?

        uri = URI.parse(repo_url)
        errors.add(:repo_url, "is not a valid URL") unless uri.is_a?(URI::HTTPS)
      end

      def author_email_is_valid
        return if repo_author_email.blank?

        errors.add(:repo_author_email, "is not a valid email") unless repo_author_email.match?(URI::MailTo::EMAIL_REGEXP)
      end

    end
  end
end