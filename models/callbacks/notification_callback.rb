require 'rest_client'

class NotificationCallback
  class << self

    attr_accessor :api_key

    def load_config(config)
      @url = config[:url]
      @should_send = config[:send]
    end

    def should_send?
      @should_send
    end

    def send_callback(course_id, user_ids, notifications)
      return unless @url and @should_send
      return if Array(user_ids).empty? or Array(notifications).empty?
      data = {
        api_key: @api_key,
        course_id: course_id,
        json_user_ids: Array(user_ids).to_json,
        json_notifications: Array(notifications).map(&:to_hash).to_json,
      }
      RestClient.post @url, data
    end
  end
end
