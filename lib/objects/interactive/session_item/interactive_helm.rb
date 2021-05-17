# frozen_string_literal: true

module Bcome::Interactive::SessionItem
  class InteractiveHelm < ::Bcome::Interactive::SessionItem::Base
    ## Contextual Helm shell

    # * Wraps helm commands for kubernetes collections and namespaces
    # * Contextual command execution within the node's kubectl context

    QUIT = '\\q'
    COMMAND_PROMPT = "enter command or '#{QUIT}' to quit>".informational + "\s#{::Helm::Validate::HELM_BINARY}" 

    def do
      wait_for_input
    end

    def start_message
      puts "\n\n"
      puts "Interactive Helm\n".underline

      puts "cluster:\s".informational + k8_cluster.remote_name
      puts "config path:\s".informational + helm_wrapper.config_path
      puts "context:\s".informational + helm_wrapper.context

      puts "\nAny commands you enter here will be passed directly to Helm scoped to your current Kubernetes node's kubectl context.\n\n"
    end

    def k8_cluster
      node.k8_cluster
    end

    def helm_wrapper
      @helm_wrapper ||= node.helm_wrapper
    end 

    def wait_for_input
      raw_command = ::Reline.readline("#{COMMAND_PROMPT}\s", true).squeeze('').to_s

      return if raw_command == QUIT

      process(raw_command) unless raw_command == QUIT
    end

    def process(command)
      @helm_wrapper.run(command)
      puts "\n"
      wait_for_input
    end

  end
end
