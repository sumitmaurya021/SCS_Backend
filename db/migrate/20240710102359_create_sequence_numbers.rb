class CreateSequenceNumbers < ActiveRecord::Migration[6.1]
  def change
    create_table :sequence_numbers do |t|
      t.integer :number, null: false

      t.timestamps
    end

    add_index :sequence_numbers, :number, unique: true
  end
end
