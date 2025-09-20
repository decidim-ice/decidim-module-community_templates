# frozen_string_literal: true

FactoryBot.define do
  factory :community_template, class: "Decidim::CommunityTemplates::CommunityTemplate" do
    organization { create(:organization) }
    source { create(:participatory_process) }
    author { Faker::Name.name }
    title { Faker::Lorem.sentence }
    links_csv { 4.times.map { Faker::Internet.url }.join(", ") }
    short_description { Faker::Lorem.sentence }
    version { "1.0.0-#{Faker::Number.number(digits: 4)}" }
    archived_at { nil }

    trait :archived do
      archived_at { Time.current }
    end
  end
end
