class RemoveOtpSentAtInUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :otp_sent_at
  end
end
