class CreateBatches < ActiveRecord::Migration[6.1]
  def change
    create_table :batches do |t|
      t.string :name, null: false
      t.string :internship_type, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :number_of_students, null: false

      t.timestamps
    end
  end
end
