require 'set'

# TODO the whole code for processing '@' should be rewritten
class AtUserObserver < Mongoid::Observer
  observe :comment, :comment_thread

  def after_create(content)
    self.class.process_at_positions(content)
  end

  def after_update(content)
    attrs = content.changed_attributes
    if attrs.include?(:title) or attrs.include?(:body)
      self.class.process_at_positions(content)
    end
  end

  def self.process_at_notifications(prev_at_positions, current_at_positions)
    content_type = content.class == CommentThread ? :thread : :comment
    prev_user_ids = prev_at_positions.map { |x| x[:user_id] }.to_set
    current_user_ids = current_at_positions.map { |x| x[:user_id] }.to_set
    # only send notifications for newly mentioned usernames
    new_user_ids = current_user_ids - prev_user_ids
    if content_type == :thread
      thread_title = content.title
      thread_id = content.id
      commentable_id = content.commentable_id
    else
      thread_title = content.comment_thread.title
      thread_id = content.comment_thread.id
      commentable_id = content.comment_thread.commentable_id
    end
    unless new_user_ids.empty?
      notification = Notification.new(
        notification_type: "at_user",
        course_id: content.course_id,
        happened_at: content.updated_at,
        info: {
          comment_id: (content.id if content_type == :comment),
          content_type: content_type,
          thread_title: thread_title,
          thread_id: thread_id,
          actor_username: content.author_with_anonymity(:username),
          actor_id: content.author_with_anonymity(:id),
          commentable_id: commentable_id,
        }
      )
      receivers = new_user_ids.map { |id| User.find(id) }
      receivers.delete(content.author)
      notification.receivers << receivers
      notification.save!
      notification.send_real_time_notification
    end
  end

  def self.process_marked_users(content, at_positions)
    content.at_position_list = at_positions
    at_positions_dict = Hash[*at_positions.collect{|x| [x[:position], x]}.flatten]
    cnt = -1
    marked_text = lambda do |at_positions_dict, cnt, text|
      if at_positions_dict[cnt]
        "<span class='mentioned_user' user_id='#{at_positions_dict[cnt][:user_id]}'>#{$1}</span>"
      else
        $1
      end
    end
    if content.respond_to? :title
      content.marked_title = content.title.gsub AT_NOTIFICATION_REGEX do
        cnt += 1
        marked_text.call(at_positions_dict, cnt, $1)
      end
    end
    content.marked_body = content.body.gsub AT_NOTIFICATION_REGEX do
      cnt += 1
      marked_text.call(at_positions_dict, cnt, $1)
    end
    print content.marked_body
    content.save!
  end

  def self.process_at_positions(content)
    content_type = content.class == CommentThread ? :thread : :comment
    text = content.body
    # we also process at notifications in titles
    text = content.title + "\n\n" + text if content_type == :thread
    at_positions = self.get_valid_at_position_list text 
    prev_at_positions = content.at_position_list
    self.process_marked_users(content, at_positions)
    self.delay.process_at_notifications(prev_at_positions, at_positions)
  end

private

  AT_NOTIFICATION_REGEX = /(?<=^|\s|\W)(@[A-Za-z0-9_]+)(?!\w)/

  def self.get_marked_text(text)
    counter = -1
    text.gsub AT_NOTIFICATION_REGEX do
      counter += 1
      "#{$1}_#{counter}"
    end
  end

  def self.get_at_position_list(text)
    list = []
    text.gsub AT_NOTIFICATION_REGEX do
      parts = $1.rpartition('_')
      username = parts.first[1..-1]
      user = User.where(username: username).first
      if user
        list << { position: parts.last.to_i, username: parts.first[1..-1], user_id: user.id }
      end
    end
    list
  end

  def self.get_valid_at_position_list(text)
    html = Nokogiri::HTML(RDiscount.new(self.get_marked_text(text)).to_html)
    html.xpath('//code').each do |c|
      c.children = ''
    end
    self.get_at_position_list html.to_s
  end
end
