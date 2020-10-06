# frozen_string_literal: true

module Bcome
  module Exception
    class Base < RuntimeError
      def initialize(message_suffix = nil)
        @message_suffix = message_suffix
      end

      def message
        "#{message_prefix}#{if @message_suffix
                              + (!message_prefix.empty? ? ':' : '').to_s + " #{@message_suffix}"
                            else
                              ''
                            end}"
      end

      def pretty_display(show_backtrace = false)
        puts "\n" + message.error
        print backtrace.join("\n") if show_backtrace
        print "\n"
      end

    end
  end
end
