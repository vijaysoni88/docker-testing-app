class AddLocationsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :locations, :json
  end
end
