class UserMailer < ApplicationMailer
    def send_otp(user)
    @user = user
    mail(to: @user.email, subject: 'Your OTP Code')
  end
end
