
module RubyPushNotifications
  module GCM

    # This class is responsible for sending notifications to the GCM service.
    #
    # @author Carlos Alonso
    class GCMPusher

      # Initializes the GCMPusher
      #
      # @param key [String]. GCM sender id to use
      #   ((https://developer.android.com/google/gcm/gcm.html#senderid))
      # @param options [Hash] optional. Options for GCMPusher. Currently supports:
      #   * open_timeout [Integer]: Number of seconds to wait for the connection to open. Defaults to 30.
      #   * read_timeout [Integer]: Number of seconds to wait for one block to be read. Defaults to 30.
      #   * slice_quantity [Integer]: Number of notifications to send to avoid hard limits. Defaults to 500.
      def initialize(key, options = {})
        @key = key
        @options = options
      end

      # Actually pushes the given notifications.
      # Assigns every notification an array with the result of each
      # individual notification.
      #
      # @param notifications [Array]. Array of GCMNotification to send.
      def push(notifications)
        Shoryuken.logger.info("Started - Pages: #{notifications.count}")
        notifications.each_with_index do |notif, page|
          Shoryuken.logger.info("Processing page: #{page+1}/#{notifications.count}")
          attempts = 0
          begin
            notif.results = GCMConnection.post notif.as_gcm_json, @key, @options
          rescue StandardError => e
            Shoryuken.logger.error "'#{self.class}', page: #{page+1}/#{notifications.count}, attempts: #{attempts}, error: '#{e.class}', message: '#{e.message}'"
            Shoryuken.logger.error e.backtrace.reject{ |l| l =~ /gem|rails/ }.join("; ")
            attempts += 1
            sleep 30 && retry if attempts < 5
          end
          Shoryuken.logger.info("Finished page: #{page+1}/#{notifications.count}")
        end
      end
    end
  end
end
