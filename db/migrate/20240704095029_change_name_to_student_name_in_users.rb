class ChangeNameToStudentNameInUsers < ActiveRecord::Migration[7.1]
  def change
    rename_column :users, :name, :student_name
  end
end
