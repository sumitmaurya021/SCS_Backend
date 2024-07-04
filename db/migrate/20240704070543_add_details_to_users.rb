class AddDetailsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :name, :string
    add_column :users, :mobile_number, :string
    add_column :users, :college_name, :string
    add_column :users, :enrollment_number, :string
    add_column :users, :branch, :string
    add_column :users, :semester, :string
    add_column :users, :course, :string
    add_column :users, :internship_type, :string
    add_column :users, :internship_start_date, :date
    add_column :users, :internship_end_date, :date
  end
end
