class Notification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :notification_type, type: String
  field :happened_at, type: Time
  field :course_id, type: String
  field :info, type: Hash

  attr_accessible :notification_type, :info, :course_id, :happened_at

  validates_presence_of :notification_type
  validates_presence_of :info

  index notification_type: 1
  index course_id: 1
  index happened_at: 1

  has_and_belongs_to_many :receivers, class_name: "User", inverse_of: :notifications, autosave: true

  def to_hash(params={})
    as_document.slice(*%w[notification_type info actor_id target_id course_id happened_at]).merge("id" => _id)
  end
end
