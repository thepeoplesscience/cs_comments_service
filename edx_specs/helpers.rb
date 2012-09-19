def log_in
  visit "/"
  click_link "Log In"
  fill_in "email", with: "student@student.com"
  fill_in "password", with: "student"
  click_button "Access My Courses"
  wait_until { page.find('.dashboard') }
end

def goto_course(course)
  visit "/courses/#{course}/info"
end

def fill_in_wmd_body(container, body)
  container.find("textarea.wmd-input").set(body)
end

def wait_for_ajax(timeout = Capybara.default_wait_time)
  # From http://artsy.github.com/blog/2012/02/03/reliably-testing-asynchronous-ui-w-slash-rspec-and-capybara/
  page.wait_until(timeout) do
    page.evaluate_script 'jQuery.active == 0'
  end
end

def generate_post
  post = {body: Faker::Lorem.paragraph(2), topic: "General"}
  post[:hash] = rand.hash.to_s(36)
  # Stick something random in the title to search for later
  post[:title] = "#{Faker::Lorem.sentence(5)} (#{post[:hash]})"
  post
end
