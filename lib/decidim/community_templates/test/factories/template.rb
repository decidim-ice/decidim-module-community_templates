# frozen_string_literal: true

FactoryBot.define do
  factory :template, class: "Decidim::CommunityTemplates::Template" do
    skip_create
    id { SecureRandom.uuid }
    title { Faker::Lorem.word }
    short_description { Faker::Lorem.sentence }
    author { Faker::Name.name }
    version { Faker::Lorem.word }
    owned { Faker::Boolean.boolean }
    source_type { Decidim::CommunityTemplates.serializers.first[:model] }
    community_template_version { Decidim::CommunityTemplates::VERSION }
    decidim_version { Decidim.version }
    archived_at { nil }
    links { [] }
    trait :archived do
      archived_at { Time.current }
    end
    trait :owned do
      owned { true }
    end
  end
end
