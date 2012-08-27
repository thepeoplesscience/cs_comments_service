require 'action_mailer'

class NotificationMailer < ActionMailer::Base
  default from: "ninjahelper.notifications@gmail.com"
  def digest(notifications)
    puts "to deliver"
    email = mail :to => "dementrock@gmail.com", :subject => "Test" do |format|
      format.html { render "test" }
    end
    binding.pry
    puts "delivered"
  end
end
