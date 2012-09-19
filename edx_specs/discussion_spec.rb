require './spec_helper'
require './post_steps'
describe "Discussion", :type => :request do

  subject { page }
  let(:thread_data){ generate_post }

  steps "Discussion Forum View" do

    it "should let you log in" do
      log_in
      goto_course "BerkeleyX/CS188/fa12"
      click_link "Discussion"
    end

    it "should have a list of threads" do
      expect { page.has_selector ".discussion-body .sidebar" }
    end

    it "should have the new post form be hidden" do
      page.find('.new-post-article').should_not be_visible
    end

    perform_steps "posting a thread"

    it "should show the new post at the top of the thread list" do
      new_first_thread_list_item = page.find('.post-list .list-item:first')
      new_first_thread_list_item.should have_content (thread_data[:title])
    end

    perform_steps "showing a newly created thread"

    perform_steps "responding to a thread"

    perform_steps "voting"

    perform_steps "editing"

    perform_steps "deleting"

  end

end
