class AddTypeToResponses < ActiveRecord::Migration[7.1]
  def change
    add_column :responses, :response_type, :string
  end
end
