require 'new_relic/agent/method_tracer'

class ThreadPresenter

  def self.get_endorsed(threads)
    # returns sparse hash {thread_key => true, ...}
    # only threads which are endorsed will have entries, value will always be true.
    endorsed_threads = {}
    thread_ids = threads.collect {|t| t._id}
    Comment.collection.aggregate(
      {"$match" => {"comment_thread_id" => {"$in" => thread_ids}, "endorsed" => true}},
      {"$group" => {"_id" => "$comment_thread_id"}}
    ).each do |res| 
      endorsed_threads[res["_id"].to_s] = true
    end
    endorsed_threads
  end

  def self.get_read_states(threads, user, course_id)
    # returns sparse hash {thread_key => [is_read, unread_comment_count], ...}
    read_states = {}
    if user
      read_dates = {}
      read_state = user.read_states.where(:course_id => course_id).first
      if read_state
        read_dates = read_state["last_read_times"].to_hash
        threads.each do |t|
          thread_key = t._id.to_s
          if read_dates.has_key? thread_key
            is_read = read_dates[thread_key] >= t.updated_at
            unread_comment_count = Comment.collection.where(
              :comment_thread_id => t._id,
              :author_id => {"$ne" => user.id},
              :updated_at => {"$gte" => read_dates[thread_key]}
              ).count
            read_states[thread_key] = [is_read, unread_comment_count]
          end
        end
      end
    end
    read_states
  end

  def self.factory(thread, user)
    # use when working with one thread at a time.  fetches extended / 
    # derived attributes from the db and explicitly initializes an instance.
    course_id = thread.course_id
    thread_key = thread._id.to_s
    is_read, unread_count = self.get_read_states([thread], user, course_id).fetch(thread_key, [false, thread.comment_count])
    is_endorsed = self.get_endorsed([thread]).fetch(thread_key, false)
    self.new thread, user, is_read, unread_count, is_endorsed
  end

  def initialize(thread, user, is_read, unread_count, is_endorsed)
    # generally not intended for direct use.  instantiated by self.factory or
    # by thread list presenters.
    @thread = thread
    @user = user
    @is_read = is_read
    @unread_count = unread_count
    @is_endorsed = is_endorsed
  end

  def to_hash with_responses=false, resp_skip=0, resp_limit=nil
    h = @thread.to_hash
    h["read"] = @is_read
    h["unread_comments_count"] = @unread_count
    h["endorsed"] = @is_endorsed || false
    if with_responses
      unless resp_skip == 0 && resp_limit.nil?
        # need to find responses first, set the window accordingly, then fetch the comments
        # bypass mongoid/odm, to get just the response ids we need as directly as possible
        responses = Content.collection.find({"comment_thread_id" => @thread._id, "parent_id" => {"$exists" => false}})
        responses = responses.sort({"sk" => 1})
        all_response_ids = responses.select({"_id" => 1}).to_a.map{|doc| doc["_id"] }
        response_ids = (resp_limit.nil? ? all_response_ids[resp_skip..-1] : (all_response_ids[resp_skip,resp_limit])) || []
        # now use the odm to fetch the desired responses and their comments
        content = Content.any_of({"parent_id" => {"$in" => response_ids}}, {"_id" => {"$in" => response_ids}}).order_by({"sk" => 1})
        response_total = all_response_ids.length
      else
        content = Content.where({"comment_thread_id" => @thread._id}).order_by({"sk"=> 1})
        response_total = content.to_a.select{|d| d.depth == 0 }.length
      end
      h = merge_comments_recursive(h, content)
      h["resp_skip"] = resp_skip
      h["resp_limit"] = resp_limit
      h["resp_total"] = response_total
    end
    h
  end

  def merge_comments_recursive thread_hash, comments
    thread_id = thread_hash["id"]
    root = thread_hash = thread_hash.merge("children" => [])
    ancestry = [thread_hash]
    # weave the fetched comments into a single hierarchical doc
    comments.each do | comment |
      thread_hash = comment.to_hash.merge("children" => [])
      parent_id = comment.parent_id || thread_id
      found_parent = false
      while ancestry.length > 0 do
        if parent_id == ancestry.last["id"] then
          # found the children collection to which this comment belongs
          ancestry.last["children"] << thread_hash
          ancestry << thread_hash
          found_parent = true
          break
        else
          # try again with one level back in the ancestry til we find the parent
          ancestry.pop
          next
        end
      end 
      if not found_parent
        # if we arrive here, it means a parent_id somewhere in the result set
        # is pointing to an invalid place.  reset the ancestry search path.
        ancestry = [root]
      end
    end
    ancestry.first
  end

  include ::NewRelic::Agent::MethodTracer
  add_method_tracer :to_hash
  add_method_tracer :merge_comments_recursive

  class << self
    include ::NewRelic::Agent::MethodTracer
    add_method_tracer :get_read_states
    add_method_tracer :get_endorsed
  end

end
