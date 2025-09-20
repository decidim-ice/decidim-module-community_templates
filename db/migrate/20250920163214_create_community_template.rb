# frozen_string_literal: true
class CreateCommunityTemplate < ActiveRecord::Migration[7.0]
  def change
    create_table :community_templates do |t|
      t.uuid :uuid, index: { unique: true }
      t.integer :decidim_organization_id,
                foreign_key: true,
                index: { name: "index_community_template_on_decidim_organization_id" }
      t.integer :source_id
      t.string :source_type
      t.string :author
      t.string :title
      t.string :links_csv
      t.string :short_description
      t.string :version
      t.datetime :archived_at

      t.timestamps
      t.index [:source_type, :source_id, :decidim_organization_id], name: "index_community_template_organization_var", unique: true
    end
  end
end
