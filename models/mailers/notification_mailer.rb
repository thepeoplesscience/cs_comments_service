require 'action_mailer'

class NotificationMailer < ActionMailer::Base
  default from: "ninjahelper.notifications@gmail.com"
  def digest(notifications)
    email = mail :to => "dementrock@gmail.com", :subject => "Test" do |format|
      format.html { render "test" }
    end
    binding.pry
  end
end
