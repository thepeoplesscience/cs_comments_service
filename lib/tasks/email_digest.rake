class NotificationDigest

  def initialize(user, profile)
    @user = user
    @profile = profile
    @config = @profile.config.with_indifferent_access
  end

  def digest_interval
    case @config[:email_digest]
    when /^every_(\d+)_hours?$/i
      $1.to_i.hours
    when /^every_day$/i
      1.days
    else
      0
    end
  end

  def should_send?
    (@config[:digest_last_updated].nil?) or (digest_interval <= Time.now - @config[:digest_last_updated])
  end

  def check_notifications_digest
    if should_send?
      send_notifications_digest
    end
  end

  def send_notifications_digest
    notifications = @user.notifications.where(course_id: @profile.course_id)
                                       .gte(happened_at: @config[:digest_last_updated] || @user.created_at)
    NotificationCallback.send_callback @profile.course_id, @user.external_id, notifications
    @profile.config[:digest_last_updated] = Time.now
    @profile.save!
  end

  class << self
    def run
      if NotificationCallback.should_send?
        User.all.each do |user|
          user.profiles.each do |profile|
            new(user, profile).check_notifications_digest
          end
        end
      end
    end
  end
end

task :email_digest => :environment do
  NotificationDigest.run
end
