# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class DummyUsers
      attr_reader :organization

      def initialize(organization)
        @organization = organization
      end

      def pick_one
        generate_users!
        existing_users.sample
      end

      def pick_sample(sample_size = 30)
        generate_users!
        existing_users.sample(sample_size)
      end

      def existing_users
        @existing_users ||= Decidim::User.where(organization: organization).where("extended_data @> ?", { demo: true }.to_json)
      end

      private

      def pick_avatar_io
        index = rand(0..avatar_count - 1)
        File.open(fixture_path.join("#{index}.jpg"), "rb")
      end

      def generated_users?
        existing_users.count.positive?
      end

      def generate_users!
        return if generated_users?

        @existing_users = nil
        generate_fake_users!
      end

      def fixture_path
        @fixture_path ||= Decidim::CommunityTemplates::Engine.root.join("spec", "fixtures", "demo_content", "avatars")
      end

      def avatar_count
        @avatar_count ||= fixture_path.children.size
      end

      def generate_fake_users!
        avatar_count.times.each { create_fake_user! }
      end

      def create_fake_user!
        Rails.logger.info("Creating fake user")
        retry_count = 0
        user = Decidim::User.create!(
          email: ::Faker::Internet.email(domain: "example.org"),
          password: "PlatformParticipant123456789",
          password_confirmation: "PlatformParticipant123456789",
          organization: organization,
          confirmed_at: Time.current,
          personal_url: ::Faker::Internet.url(host: "example.org"),
          nickname: ::Faker::Internet.username.parameterize,
          name: ::Faker::Name.name,
          about: ::Faker::Lorem.paragraph,
          extended_data: { demo: true },
          tos_agreement: true,
          accepted_tos_version: 1.day.from_now
        )
        user.avatar.attach(
          io: pick_avatar_io,
          filename: "avatar.jpg"
        )
        user.avatar.save
        user.save!
        user.reload
      rescue StandardError => e
        Rails.logger.error("Error creating fake user: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        retry_count += 1
        retry if retry_count < 10
        raise e
      end
    end
  end
end
