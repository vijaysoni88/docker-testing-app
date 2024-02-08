class CreateResponses < ActiveRecord::Migration[7.1]
  def change
    create_table :responses do |t|
      t.jsonb :json_data
      t.timestamps
    end
  end
end
