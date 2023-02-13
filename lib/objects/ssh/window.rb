# frozen_string_literal: true

module Bcome
  module Ssh
    class Window
      attr_reader :lines

      include ThreadSafeSingleton

      def initialize(*_params)
        @lines = []
      end

      def add(node, log_line)
        multi_line = log_line =~ /\n/ ? true : false

        @lines << if ::Bcome::Orchestrator.instance.is_multi_node?
                    "\n#{node.namespace}".terminal_prompt + "\n#{log_line}"
                  else
                    log_line
                  end

        pop
      end

      def pop
        line = @lines.pop.force_encoding("UTF-8")
        print line
      end
    end
  end
end
