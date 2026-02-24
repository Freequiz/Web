class ApplicationMailer < ActionMailer::Base
  default from: email_address_with_name("noreply@freequiz.ch", "Freequiz")
  layout "mailer"
end
