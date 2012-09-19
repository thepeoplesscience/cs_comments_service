require './spec_helper'

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

    it "should show and hide the new post form" do
      click_link 'New Post'
      page.find('.new-post-article').should be_visible
      click_link 'Cancel'
      wait_until { !page.find('.new-post-article').visible? }
      page.find('.new-post-article').should_not be_visible
    end

    it "should let you create a new post" do
      click_link 'New Post'
      new_post_container = page.find('.new-post-article')
      old_first_thread_title = page.find('.post-list .list-item:first .title').text
      new_post_container.should be_visible
      fill_in_wmd_body(new_post_container, thread_data[:body])
      new_post_container.find('.new-post-title').set(thread_data[:title])
      click_button "Add post"
      new_first_thread_list_item = page.find('.post-list .list-item:first')
      new_first_thread_list_item.should have_content (thread_data[:title])
      new_first_thread_list_item.should_not have_content old_first_thread_title

      thread_container = page.find('article.discussion-article .thread-content-wrapper')
      thread_container.should have_content thread_data[:body]
      thread_container.should have_content thread_data[:title]
      thread_data[:id] = page.find('article.discussion-article')['data-id']
    end

    it "should show the thread's body when a thread is clicked" do
      # Navigate to index first
      goto_course "BerkeleyX/CS188/fa12"
      click_link "Discussion"

      page.find('.post-list .list-item:first a').click
      page.find('.new-post-article').should_not be_visible

      thread_container = page.find('article.discussion-article .thread-content-wrapper')
      thread_container.should have_content thread_data[:body]
      thread_container.should have_content thread_data[:title]
    end

    it "should show the thread as followed" do
      thread_container = page.find('article.discussion-article .thread-content-wrapper')
      thread_container.should have_selector('.is-followed')
    end

    it "should let you respond to a post" do
      response_form = page.find('.discussion-reply-new')
      spammy_comment = Faker::Company.bs
      fill_in_wmd_body response_form, spammy_comment
      response_form.find('.discussion-submit-post').click
      responses = page.find('.responses')
      responses.should have_content spammy_comment
    end

    it "should let you post a comment on a response" do
      comment = "Help! I've been hacked to produce spam!"
      first_response = page.find('.responses li:first')
      first_response.find('.wmd-input').click
      fill_in_wmd_body(first_response, comment)
      first_response.find('.discussion-submit-comment').click
      first_response.find('.wmd-input').should_not have_content(comment)
      first_response.find('.comments .response-body').should have_content(comment)
    end

    it "should let you vote on a post" do
      vote_btn = page.find('article.discussion-article .thread-content-wrapper a.vote-btn')
      vote_btn.find('.votes-count-number').should have_content '0'
      vote_btn.click
      vote_btn.find('.votes-count-number').should have_content '1'
    end
  end

end
