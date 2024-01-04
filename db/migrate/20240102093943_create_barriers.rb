class CreateBarriers < ActiveRecord::Migration[7.1]
  def change
    create_table :barriers do |t|
      t.string :name
      t.float :latitude
      t.float :longitude
      t.integer :size
      t.boolean :enabled

      t.timestamps
    end
  end
end
