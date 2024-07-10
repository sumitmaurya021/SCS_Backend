class AddIntershipAreaInUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :internship_area, :string
  end
end
