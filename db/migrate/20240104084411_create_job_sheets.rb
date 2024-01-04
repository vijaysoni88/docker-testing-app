class CreateJobSheets < ActiveRecord::Migration[7.1]
  def change
    create_table :job_sheets do |t|
      t.text :start_address
      t.text :end_address
      t.string :customer_name
      t.string :site_contact
      t.string :contact_number
      t.string :job_number
      t.text :job_instruction

      t.timestamps
    end
  end
end
