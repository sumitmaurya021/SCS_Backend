class AddSequenceNumberToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :sequence_number, :integer
  end
end
