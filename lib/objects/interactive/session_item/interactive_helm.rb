# frozen_string_literal: true

module Bcome::Interactive::SessionItem
  class InteractiveHelm < ::Bcome::Interactive::SessionItem::Base
    ## Contextual Helm shell

    # * Wraps helm commands for kubernetes collections and namespaces
    # * Contextual command execution within the node's kubectl context

    QUIT_HELM = '\\q'.freeze
    REAUTH_KEY = '\\r'.freeze
    HELP_KEY = '\\?'

    def do
      ::Bcome::Orchestrator.instance.silence_command_output!
      show_menu
      wait_for_input
    end

    def start_message
      puts "\nAny commands you enter here will be passed directly to Helm scoped to this bcome node's kubectl context.\n"
    end

    def command_prompt
      return "#{node.prompt_breadcrumb(focus: false)}" + "\s#{::Bcome::Helm::Validate::HELM_BINARY}\s"
    end
 
    def k8_cluster
      node.k8_cluster
    end

    def helm_wrapper
      @helm_wrapper ||= node.helm_wrapper
    end 

    def wait_for_input
      raw_command = ::Readline.readline("#{command_prompt}", true).squeeze('').to_s

      if raw_command == QUIT_HELM
        return
      elsif reauth?(raw_command)
        puts "\n"
        reauth && (puts "\n") && wait_for_input
      elsif show_menu?(raw_command)
        show_menu
      else
        process(raw_command)
      end
    end

    def show_menu
      info = "\\q or exit to quit\n\\r to reauthenticate to your cluster\n\\? this message".informational
      puts "\n#{info}\n\n"
    end

    def reauth
      k8_cluster.reauthorize!
    end

    def process(command)  
      skip_output = true
      helm_wrapper.run(command, skip_output)
      puts "\n"
      wait_for_input
    end

    def show_menu?(input)
      input == HELP_KEY
    end

    def reauth?(input)
      input == REAUTH_KEY
    end
  end
end
