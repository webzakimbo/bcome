# frozen_string_literal: true

module Bcome
  module Ssh
    class Connector
      include ::Bcome::LoadingBar::Handler

      class << self
        def connect(node, config = {})
          handler = new(node, config)
          handler.connect
        end
      end

      def initialize(node, config)
        @node = node
        @config = config
        set_servers
        @connected_machines = []
        @connection_exceptions = {}
      end

      def show_progress?
        @config[:show_progress] ? true : false
      end

      def ping?
        @config[:is_ping] ? true : false
      end

      def connect
        return if (number_unconnected_machines == 0 && !ping?)

        if show_progress?
          wrap_indicator type: :progress, size: @servers_to_connect.size, title: "Opening connections" do
            open_connections
          end       
        else
          open_connections
        end

        report_connection_outcome
      end

      def report_connection_outcome
        print "\n"

        if ping?
          @connected_machines.pmap do |machine|
            puts machine.print_ping_result
          end

          # If any machines remain, then we couldn't connect to them
          @servers_to_connect.each do |machine|
            ping_result = {
              success: false,
              error: @connection_exceptions[machine]
            }
            puts machine.print_ping_result(ping_result)
          end
        end

        puts "Failed to connect to #{@servers_to_connect.size} node#{@servers_to_connect.size > 1 ? 's' : ''}".error if @servers_to_connect.any?
      end

      def open_connections
        @servers_to_connect.pmap do |machine|
          begin
            machine.open_ssh_connection(ping?)
            if machine.has_ssh_connection?
              @servers_to_connect -= [machine]
              @connected_machines << machine
              signal_success if show_progress?
            else
              signal_failure if show_progress?
            end
          rescue Bcome::Exception::CouldNotInitiateSshConnection, ::Bcome::Exception::InvalidProxyConfig => e
            signal_failure if show_progress?
            @connection_exceptions[machine] = e
          rescue Errno::EPIPE
            raise ::Bcome::Exception::Generic.new "Process terminated"
          end
        end
      end

      private

      def set_servers
        @servers_to_connect = machines.dup
      end

      def number_unconnected_machines
        @servers_to_connect.select { |machine| !machine.has_ssh_connection? }.size
      end

      def machines
        skip_for_hidden = true # Skip servers with hidden namespaces
        @node.server? ? [@node] : @node.machines(skip_for_hidden)
      end
    end
  end
end
