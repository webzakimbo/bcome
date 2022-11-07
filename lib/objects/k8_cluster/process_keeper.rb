# frozen_string_literal: true

module Bcome
  module K8Cluster
    class ProcessKeeper

      include ThreadSafeSingleton

      def initialize
        @pids = []
      end

      def <<(pid)
        @pids << pid
      end

      def kill_pids
        @pids.each do |pid|
          ::Process.kill(SIGKILL, pid)
        end
      end
    end
  end
end
