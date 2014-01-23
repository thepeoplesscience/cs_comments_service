require_relative 'thread'

class ThreadListPresenter

  def initialize(threads, user, course_id)
    read_states = ThreadPresenter.get_read_states(threads, user, course_id)
    threads_endorsed = ThreadPresenter.get_endorsed(threads)
    @presenters = []
    threads.each do |thread|
      thread_key = thread._id.to_s
      is_read, unread_count = read_states.fetch(thread_key, [false, thread.comment_count])
      is_endorsed = threads_endorsed.fetch(thread_key, false)
      @presenters << ThreadPresenter.new(thread, user, is_read, unread_count, is_endorsed)
    end
  end

  def to_hash
    @presenters.map { |p| p.to_hash }
  end

end
