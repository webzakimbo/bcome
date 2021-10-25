# frozen_string_literal: true

module Bcome::Interactive::SessionItem
  class InteractiveKubectl < ::Bcome::Interactive::SessionItem::Base

    END_SESSION_KEYS = ['\\q', 'exit']
    HELP_KEY = '\\?'

    def do
      puts ''
      puts "\nContextual Kubectl".bc_yellow.bold
      show_menu
      puts ''
      action
    end

    def action
      input = get_input

      return if exit?(input)
      action if comment?(input)

      # TODO
      # bcome :pod, :name OR bcome :cronjob, :name etc

      if commands = passthru_bcome?(input)
        method = commands.first
        node.send(method)
        action
      end

      #if @to_snapshot
      #  node.set_context(@to_snapshot)
      #  @to_snapshot = nil
      #end

      if show_menu?(input)
        show_menu
      else
        run_kc(input)
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

        runner = node.delegated_kubectl_cmd(command)
        puts runner
      rescue JSON::ParserError
        puts "Invalid command '#{command}'".error
      end
    end

    def show_menu
      info = "\\q or exit to quit\n\\? this message".informational
      puts "\n#{info}\n\n"
    end

    def terminal_prompt
      "#{node.kubectl_context}>\s"
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
 
      #if method == "get"
      #  @to_snapshot = tokens[1..tokens.size].join("\s")
      #end

      if passthru_commands.include?(tokens.first) 
        return tokens
      else
        return false
      end
    end

    def passthru_commands
      ["pathways"]
      #["tree", "pathways", "reload", "bcome"]
    end

    def show_menu?(input)
      input == HELP_KEY
    end

    def start_message; end

  end
end
