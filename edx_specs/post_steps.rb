require './spec_helper'

shared_steps "posting a thread" do
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
end

shared_steps "showing a newly created thread" do
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
end

shared_steps "responding to a thread" do
  it "should let you respond to a post" do
    response_form = page.find('.discussion-reply-new')
    spammy_comment = Faker::Company.bs
    fill_in_wmd_body response_form, spammy_comment
    response_form.find('.discussion-submit-post').click
    responses = page.find('.responses')
    responses.should have_content spammy_comment
  end

  it "should let you post a comment on a response" do
    comment = "Help! I've been hacked by a spambot!"
    first_response = page.find('.responses li:first')
    first_response.find('.wmd-input').click
    fill_in_wmd_body(first_response, comment)
    first_response.find('.discussion-submit-comment').click
    first_response.find('.wmd-input').should_not have_content(comment)
    first_response.find('.comments .response-body').should have_content(comment)
  end
end

shared_steps "voting" do
  it "should let you vote on a post" do
    post = content_element(page.find('article.discussion-article .thread-content-wrapper'))
    post.vote_count.should == '0'
    post.vote_button.click
    post.vote_count.should == '1'
    post.vote_button.click
    post.vote_count.should == '0'
  end

  it "should let you vote on a response" do
    first_response = content_element(page.find('.responses li:first'))
    first_response.vote_count.should == '0'
    first_response.vote_button.click
    first_response.vote_count.should == '1'
  end
end

shared_steps "editing" do
  it "should let you edit your own thread" do
    thread = content_element(page.find('article.discussion-article'))
    thread.edit_button.click
    new_body = 'Latin is lame'
    thread.fill_in_wmd_body(new_body)
    thread.submit_button.click
    thread.should_not have_selector('.edit-post-form')
    thread.body.should have_content new_body
  end

  it "should let you edit your own response" do
    first_response = content_element(page.find('.responses li:first'))
    first_response.edit_button.click
    new_body = 'Sorry for the spam, I was hacked.'
    first_response.fill_in_wmd_body(new_body)
    first_response.submit_button.click
    first_response.should_not have_selector('.edit-response-form')
    first_response.body.should have_content new_body
  end
end

shared_steps "deleting" do
  it "should let you delete your own response" do
    thread = content_element(page.find('article.discussion-article'))
    response_count = thread.responses.length
    first_response = content_element(page.find('.responses li:first'))
    first_response.delete_button.click
    thread.responses.length.should == response_count - 1
  end

  it "should let you delete your own thread" do
    thread = content_element(page.find('article.discussion-article .thread-content-wrapper'))
    thread.delete_button.click
    page.should_not have_content(thread_data[:body])
  end
end
