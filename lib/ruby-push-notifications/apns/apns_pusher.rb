
module RubyPushNotifications
  module APNS
    # This class coordinates the process of sending notifications.
    # It takes care of reopening closed APNSConnections and seeking back to
    # the failed notification to keep writing.
    #
    # Remember that APNS doesn't confirm successful notification, it just
    # notifies when one went wrong and closes the connection. Therefore, this
    # APNSPusher reconnects and rewinds the array until the notification that
    # Apple rejected.
    #
    # @author Carlos Alonso
    class APNSPusher

      # @param certificate [String]. The PEM encoded APNS certificate.
      # @param sandbox [Boolean]. Whether the certificate is an APNS sandbox or not.
      # @param options [Hash] optional. Options for APNSPusher. Currently supports:
      #   * connect_timeout [Integer]: Number of seconds to wait for the connection to open. Defaults to 30.
      #   * slice_quantity [Integer]: Number of notifications to send to avoid hard limits. Defaults to 5000.
      def initialize(certificate, sandbox, password = nil, options = {})
        @certificate = certificate
        @pass = password
        @sandbox = sandbox
        @options = options
      end

      def open_connection
        APNSConnection.open @certificate, @sandbox, @pass, @options
      end

      # Pushes the notifications.
      # Builds an array with all the binaries (one for each notification and receiver)
      # and pushes them sequentially to APNS monitoring the response.
      # If an error is received, the connection is reopened and the process
      # continues at the next notification after the failed one (pointed by the response error)
      #
      # For each notification assigns an array with the results of each submission.
      #
      # @param notifications [Array]. All the APNSNotifications to be sent.
      def push(notifications)
        Shoryuken.logger.info("Started - Pages: #{notifications.count}")
        conn = open_connection
        notifications.each_with_index do |notification, page|
          Shoryuken.logger.info("Processing page: #{page+1}/#{notifications.count}")
          binaries = []
          notification.each_message(binaries.count) do |msg|
            binaries << msg
          end
          results = []
          i = 0
          while i < binaries.count
            attempts = 0
            begin
              conn.write binaries[i]
              if i == binaries.count-1
                conn.flush
                rs, = IO.select([conn], nil, nil, 2)
              else
                rs, = IO.select([conn], [conn])
              end
            rescue StandardError => e
              Shoryuken.logger.error "'#{self.class}', page: #{page+1}/#{notifications.count}, attempts: #{attempts}, item: #{i}, error: '#{e.class}', message: '#{e.message}'"
              Shoryuken.logger.error e.backtrace.reject{ |l| l =~ /gem|rails/ }.join("; ")
              attempts += 1
              conn = open_connection unless conn.open?
              retry if attempts < 5
            end

            if rs && rs.any?
              packed = rs[0].read 6
              if packed.nil? && i == 0
                # The connection wasn't properly open
                # Probably because of wrong certificate/sandbox? combination
                results << UNKNOWN_ERROR_STATUS_CODE
              else
                err = packed.unpack 'ccN'
                results.slice! err[2]..-1
                results << err[1]
                i = err[2]
                conn = open_connection unless conn.open?
              end
            else
              results << NO_ERROR_STATUS_CODE
            end

            i += 1
          end
          notification.results = APNSResults.new(results.slice! 0, notification.count)
          notif.paired_results = notif.pair_results(notif.results, notif.instance_variable_get("@tokens"))
        end
        begin
          conn.close
        rescue StandardError => e
          Shoryuken.logger.error "Close connection #{e.message}"
        end
        Shoryuken.logger.info("Finished")
      end
    end
  end
end
