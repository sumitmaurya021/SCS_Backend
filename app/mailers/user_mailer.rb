class UserMailer < ApplicationMailer
    def send_otp(user)
    @user = user
    mail(to: @user.email, subject: 'Your OTP Code')
  end

  def send_offer_letter(user)
    @user = user

    # Generate the PDF from the template
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string(
        template: 'users/offer_letter', # No need to include the file extension
        layout: 'pdf_layout', # Assuming you have a 'pdf_layout.html.erb' for styling
        locals: { user: @user }
      ),
      page_size: 'A4',
      margin: { top: 0, bottom: 0, left: 0, right: 0 } # Remove margins
    )

    # Attach the generated PDF to the email
    attachments['offer_letter.pdf'] = { mime_type: 'application/pdf', content: pdf }

    mail(to: @user.email, subject: 'Your Offer Letter')
  end

end
