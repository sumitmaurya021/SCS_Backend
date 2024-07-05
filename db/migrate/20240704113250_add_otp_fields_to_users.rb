class AddOtpFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :otp, :string
    add_column :users, :otp_sent_at, :datetime
  end
end
