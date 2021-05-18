# frozen_string_literal: true

module Bcome::Interactive::SessionItem
  class InteractiveHelm < ::Bcome::Interactive::SessionItem::Base
    ## Contextual Helm shell

    # * Wraps helm commands for kubernetes collections and namespaces
    # * Contextual command execution within the node's kubectl context

    QUIT_HELM = '\\q'.freeze

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

    def command_prompt
      "enter command or '#{QUIT_HELM}' to quit>".informational + "\s#{::Bcome::Helm::Validate::HELM_BINARY}"
    end

    def k8_cluster
      node.k8_cluster
    end

    def helm_wrapper
      @helm_wrapper ||= node.helm_wrapper
    end 

    def wait_for_input
      raw_command = ::Reline.readline("#{command_prompt}\s", true).squeeze('').to_s

      return if raw_command == QUIT_HELM
     
      puts "\n"
      process(raw_command) unless raw_command == QUIT_HELM
    end

    def process(command)  
      skip_output = true
      @helm_wrapper.run(command, skip_output)
      puts "\n"
      wait_for_input
    end

  end
end
