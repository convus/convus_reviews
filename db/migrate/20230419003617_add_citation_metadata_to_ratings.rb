class AddCitationMetadataToRatings < ActiveRecord::Migration[7.0]
  def change
    add_column :ratings, :citation_metadata, :jsonb
  end
end
