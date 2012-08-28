class NotificationDigest

  def initialize(user, course_id, user_config)
    @user = user
    @course_id = course_id
    @user_config = user_config.with_indifferent_access
  end

  def digest_interval
    case @user_config[:email_digest]
    when /^every_(\d+)_hours?$/i
      $1.to_i.hours
    when /^every_day$/i
      1.days
    else
      0
    end
  end

  def should_send?
    digest_interval <= Time.now - Time.parse(@user_config[:digest_last_updated] || @user.created_at.to_s)
  end

  def check_notifications_digest
    if should_send?
      send_notifications_digest
    end
  end

  def send_notifications_digest
    notifications = @user.notifications.where(course_id: @course_id, unread: true)
                                       .gte(happened_at: @user_config[:digest_last_updated] || @user.created_at)
    notifications.update_all(unread: false)
    NotificationCallback.send_callback @course_id, @user.external_id, notifications
    @user_config[:digest_last_updated] = Time.now
    @user.save!
  end

  class << self

    def check_notifications_digest(user)
      user.profiles.each do |profile|
        new(user, profile.course_id, profile.config).check_notifications_digest
      end
    end

    def run
      
      if NotificationCallback.should_send?
        User.all.each &check_notifications_digest
      end
    end
  end
end

task :update_notifications_digest => :environment do
  NotificationDigest.run
end
