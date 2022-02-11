# frozen_string_literal: true

module Bcome::Interactive::SessionItem
  class InteractiveKubectl < ::Bcome::Interactive::SessionItem::Base

    END_SESSION_KEYS = ['\\q', 'exit']
    HELP_KEY = '\\?'
    REAUTH_KEY = '\\r'

    def start_message
      puts "\nAny commands you enter here will be passed directly to your bcome node's kubectl context.\n"
    end

    def do
      ::Bcome::Orchestrator.instance.silence_command_output!
      show_menu
      action
    end

    def action
      input = get_input

      return if exit?(input)
      action if comment?(input)

      if commands = passthru_bcome?(input)
        method = commands.first
        node.send(method)
        action
      end

      if show_menu?(input)
        show_menu
      elsif reauth?(input)
        puts "\n"
        reauth
        puts "\n"
      else
        puts "\n"
        runner = run_kc(input) && action
        puts "\n"
      end

      action
    end

    def run_kc(raw_command)
      begin
        # Capture any piped input. This will need to be re-applied to the resulting command after the system has added the contextual components
        captures = raw_command.split(/(?<!\\)\|/)
        command = captures[0]
        pipes = captures[1..captures.length].join("") if captures.length > 1
        
        ::Bcome::PipedInput.instance.pipe = pipes if pipes
 
        delegate_kubectl_command(command)
      rescue JSON::ParserError
        puts "Invalid command '#{command}'".error
      end
    end

    def delegate_kubectl_command(command)
      # We must run 'delegated_kubectl_cmd' as this hands off to the underlying
      # operating system, allowing features like 'kubectl edit' which must open an editor
      # and allow for saving.

      # It does mean that for now we don't have an elegant way of automatically reconnecting 
      # to the cluster when the access token expires, hence the manual /r 'reauth' method.
      exit_code = node.delegated_kubectl_cmd(command)
      return 
    end
 
    def show_menu
      info = "\\q or exit to quit\n\\r to reauthenticate to your cluster\n\\? this message".informational
      puts "\n#{info}\n\n"
    end

    def reauth
      k8_cluster.reauthorize!
    end

    def k8_cluster
      node.k8_cluster
    end 

    def terminal_prompt
      return "#{node.prompt_breadcrumb(focus: false)}" + "\skubectl\s"
    end

    def exit?(input)
      END_SESSION_KEYS.include?(input)
    end

    def comment?(input)
      input =~ /^#.+$/
    end

    def passthru_bcome?(input)
      tokens = input.split(/\s+/)
      method = tokens.first
 
      if passthru_commands.include?(tokens.first) 
        return tokens
      else
        return false
      end
    end

    def passthru_commands
      ["routes", "tree"]
    end

    def show_menu?(input)
      input == HELP_KEY
    end

    def reauth?(input)
      input == REAUTH_KEY
    end
  end
end
