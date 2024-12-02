class CreateBatchUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :batch_users do |t|
      t.references :batch, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
