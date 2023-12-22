class CreateKmzs < ActiveRecord::Migration[7.1]
  def change
    create_table :kmzs do |t|
      t.timestamps
    end

    add_reference :kmzs, :kmz_attachment, polymorphic: true, index: true
  end
end
