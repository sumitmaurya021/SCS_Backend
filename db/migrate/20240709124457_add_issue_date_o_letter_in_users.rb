class AddIssueDateOLetterInUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :issue_date_of_letter, :date, null: true
  end
end
