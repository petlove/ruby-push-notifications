
module RubyPushNotifications
  module GCM
    # Encapsulates a GCM Notification.
    # By default only Required fields are set.
    # (https://developer.android.com/google/gcm/server-ref.html#send-downstream)
    #
    # @author Carlos Alonso
    class GCMNotification
      include RubyPushNotifications::NotificationResultsManager

      # Initializes the notification
      #
      # @param [Array]. Array with the receiver's GCM registration ids.
      # @param [Hash]. Payload to send.
      def initialize(registration_ids, data)
        @registration_ids = registration_ids
        @data = data
      end

      # @return [String]. The GCM's JSON format for the payload to send.
      #    (https://developer.android.com/google/gcm/server-ref.html#send-downstream)
      def as_gcm_json
        JSON.dump(
          registration_ids: @registration_ids,
          data: @data
        )
      end

      def self.slice(all_registration_ids, data, quantity=500)
        all_registration_ids.each_slice(quantity).each_with_object([]) do |registration_ids, list|
          list << new(registration_ids, data)
        end
      end
    end
  end
end
