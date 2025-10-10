# frozen_string_literal: true

FactoryBot.define do
  factory :template_metadata, class: "Decidim::CommunityTemplates::TemplateMetadata" do
    skip_create
    id { SecureRandom.uuid }
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    author { Faker::Name.name }
    version { Faker::Lorem.word }
    community_templates_version { Decidim::CommunityTemplates::VERSION }
    decidim_version { Decidim.version }
    archived_at { nil }
    links { [] }

    transient do
      organization { create(:organization, default_locale: I18n.available_locales.sample, available_locales: I18n.available_locales) }
    end

    initialize_with do
      instance = new(attributes)
      instance.id ||= SecureRandom.uuid
      process = create(:participatory_process, organization: organization)
      instance[:@class] = process.class.name
      serializer = Decidim::CommunityTemplates::Serializers::ParticipatoryProcess.init(
        model: process,
        locales: [organization.default_locale],
        with_manifest: true,
        metadata: instance.as_json
      )
      serializer.metadata_translations!
      serializer.save!(Decidim::CommunityTemplates.catalog_path)
      Decidim::CommunityTemplates::TemplateSource.create!(
        source: process,
        template_id: instance.id,
        organization: organization
      )

      instance
    end

    trait :archived do
      archived_at { Time.current }
    end
  end
end
