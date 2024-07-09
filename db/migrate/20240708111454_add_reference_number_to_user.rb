class AddReferenceNumberToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :reference_number, :string, null: true
  end
end
