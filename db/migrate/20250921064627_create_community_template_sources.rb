# frozen_string_literal: true
class CreateCommunityTemplateSources < ActiveRecord::Migration[7.0]
  def change
    create_table :community_template_sources do |t|
      # TemplateSource:
      # - template_id: the uuid of the template
      # - source_id:
      # - source_type:
      # - timestamp: the timestamp of the binding
      # - decidim_organization_id: the id of the organization using the template
      t.integer :decidim_organization_id,
                foreign_key: true,
                index: { name: "index_community_template_sources_on_decidim_organization_id" }
      t.string :template_id, index: true
      t.integer :source_id
      t.string :source_type

      t.index [:source_type, :source_id, :decidim_organization_id], name: "unique_community_template_sources_on_organization", unique: true

      t.timestamps
    end
  end
end
