# frozen_string_literal: true

module Bcome::Orchestration::Catalogue
  class RemoteCli < Bcome::Orchestration::Base

    QUIT = '\\q'

    def execute
      puts "Remote CLI\n".bc_yellow.bold
      wait_for_command_input
    end

    def container
      @container ||= get_container
    end

    protected

    def command_prefix
      raise "Missing command prefix" unless @arguments[:command_prefix] 
      @arguments[:command_prefix]
    end

    def terminal_prompt
      "enter command> ".informational + command_prefix.resource_key + "\s"
    end

    private

    def process_command(raw_command)
      full_command = "#{command_prefix} #{raw_command}"
      puts "\n"
      container.run(full_command)
      wait_for_command_input
    end

    def get_container
      raise "Missing argument container_name" unless @arguments[:container_name]
      @c = all_containers.detect{|container| container.identifier =~ /#{@arguments[:container_name]}/}
      raise "Cannot find container named '#{@arguments[:container_name]}" unless @c
      return @c
    end

    def all_containers
      pod.machines
    end

    def pod
      raise "Registry method must be placed on a Pod." unless @node.is_a?(::Bcome::Node::K8Cluster::Pod)
      return @node
    end

    def wait_for_command_input
      raw_command = wait_for_input
      process_command(raw_command) unless raw_command == QUIT
    end

    def wait_for_input
      ::Readline.readline(terminal_prompt, true).squeeze('').to_s
    end

  end
end
