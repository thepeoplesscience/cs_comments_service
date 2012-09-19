require './spec_helper'
require './post_steps'
describe "Inline", :type => :request do

  subject { page }
  let(:thread_data){ generate_post }

  steps "discussion view" do
    it "should let you log in" do
      log_in
    end

    it "should navigate to a courseware content" do
      goto_course "BerkeleyX/CS188/fa12"
      click_link "Courseware"
      # This is a lame way of clicking Week 0, for some reason it doesn't find it
      click_link "Week\xC2\xA00"
      click_link "Math"
    end

    it "should show and hide the inline discussion" do
      click_link "Show Discussion"
      wait_for_ajax
      click_link "Hide Discussion"
      wait_for_ajax
      click_link "Show Discussion"
    end

    it "should have the new post form be hidden" do
      page.find('.new-post-article').should_not be_visible
    end

    perform_steps "posting a thread"

    #perform_steps "showing a newly created thread"

    it "should navigate back to a courseware content" do
      goto_course "BerkeleyX/CS188/fa12"
      click_link "Courseware"
      # This is a lame way of clicking Week 0, for some reason it doesn't find it
      click_link "Week\xC2\xA00"
      click_link "Math"
      click_link "Show Discussion"
      wait_for_ajax
      page.should have_content thread_data[:title]
    end

    it "should expand the thread" do
      page.find('.discussion-article').find_link('View discussion').click
      page.should have_content thread_data[:body]
    end

    perform_steps "responding to a thread"

    perform_steps "voting"

    perform_steps "editing"

    it "should be at the courseware page" do
      current_path.index('courseware').should_not be_nil
      current_path.index('forum').should be_nil
    end

    perform_steps "deleting"
  end
end
