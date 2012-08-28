class Notification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :notification_type, type: String
  field :happened_at, type: Time
  field :course_id, type: String
  field :info, type: Hash
  field :unread, type: Boolean, default: true

  attr_accessible :notification_type, :info, :course_id, :happened_at, :unread

  validates_presence_of :notification_type
  validates_presence_of :info

  index notification_type: 1
  index course_id: 1
  index happened_at: 1

  has_and_belongs_to_many :receivers, class_name: "User", inverse_of: :notifications, autosave: true

  def to_hash(params={})
    as_document.slice(*%w[notification_type info actor_id target_id course_id happened_at unread]).merge("id" => _id)
  end

  def send_real_time_notification
    user_ids = receivers.where("profiles.course_id" => course_id,
                               "profiles.config.email_digest" => :real_time)
                        .map(&:id)
    NotificationCallback.send_callback course_id, user_ids, self
    self.update(unread: false)
  end

end
