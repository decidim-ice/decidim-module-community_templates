# frozen_string_literal: true

FactoryBot.define do
  factory :community_template_source, class: "Decidim::CommunityTemplates::TemplateSource" do
    organization { create(:organization) }
    source { create(:participatory_process, organization: organization || create(:organization)) }
    template_id { SecureRandom.uuid }
  end
end
