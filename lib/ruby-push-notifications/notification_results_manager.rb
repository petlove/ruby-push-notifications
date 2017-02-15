module RubyPushNotifications
  # This module contains the required behavior expected by particular notifications
  #
  # @author Carlos Alonso
  module NotificationResultsManager
    extend Forwardable

    def_delegators :@results, :success, :failed, :individual_results

    # The corresponding object with the results from sending this notification
    # that also will respond to #success, #failed and #individual_results
    attr_accessor :results, :paired_results

    def pair_results(tokens)
      @paired_results ||= tokens.with_index.each_with_object({}) do |(token, i), list|
        list[token] = individual_results[i]
      end
    end
  end
end
