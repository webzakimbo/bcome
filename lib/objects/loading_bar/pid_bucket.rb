# frozen_string_literal: true

module Bcome
  module LoadingBar
    class PidBucket

      include ThreadSafeSingleton

      def initialize
        @pids = []
      end

      def <<(pid)
        @pids << pid
      end

      def -(pid)
        @pids -= [pid]
      end

      def stop_all
        @pids.map do |pid|
          ::Process.kill(::Bcome::LoadingBar::Indicator::Base::SIGNAL_STOP, pid)
        end
      end
    end
  end
end
