require './spec_helper'
require './post_steps'
describe "Inline Discussion", :type => :request do

  subject { page }
  let(:thread_data){ generate_post }

  steps "Inline discussion view" do
    it "should let you log in" do
      log_in
    end

    it "should navigate to a courseware content" do
      goto_course "BerkeleyX/CS188/fa12"
      click_link "Courseware"
      # This is a lame way of clicking Week 0, for some reason it doesn't find it
      page.find('#accordion .chapter a').click
      #click_link "Week 0"
      click_link '0'  # This also works
      click_link "Math"
      save_and_open_page
    end

    it "should show and hide the inline discussion" do
      click_link "Show Discussion"
      click_link "Hide Discussion"
    end

    it "should have the new post form be hidden" do
      page.find('.new-post-article').should_not be_visible
    end

    perform_steps "posting a thread"

    perform_steps "showing a newly created thread"

    perform_steps "responding to a thread"

    perform_steps "voting"

    perform_steps "editing"

    perform_steps "deleting"
  end
end
