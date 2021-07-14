# frozen_string_literal: true

module Bcome::Interactive::SessionItem
  class InteractiveKubectl < ::Bcome::Interactive::SessionItem::Base

    END_SESSION_KEY = '\\q'
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

      # IF command = "get"
        # Snapshot on the fly in a separate process
          # and refresh node.crds[RESOURCE_TYPE] on the fly

      if commands = passthru_bcome?(input)
        method = commands.first
        node.send(method)
        action
      end

        #if method == "bcome"
        #  ## VVVVVV rough & ready POC to see if this makes sense
        #  args = commands[1..commands.size]
        #  crd_type = args[0].camelcase            
        #  identifier = args[1]

         # crd = node.crds["Pod"].select{|crd| crd.identifier == identifier }.first 
         # if crd
         #   ::Bcome::Workspace.instance.set(context: crd)
         # else
         #    puts "Cannot find #{crd_type} #{identifier}".error
         # end
         # action
        #else
        #end
      if show_menu?(input)
        show_menu
      else
        run_kc(input)
      end

      action
    end

    def run_kc(command)
      begin
        runner = node.delegated_kubectl_cmd(command)
        puts runner
        #puts runner.data.stdout
      rescue JSON::ParserError
        puts "Invalid command '#{command}'".error
      end
    end

    def show_menu
      info = "\\q to quit\n\\? this message".informational
      puts "\n#{info}\n\n"
    end

    def terminal_prompt
      "#{node.kubectl_context}>\s"
    end

    def exit?(input)
      input == END_SESSION_KEY
    end

    def comment?(input)
      input =~ /^#.+$/
    end

    def passthru_bcome?(input)
      tokens = input.split(/\s+/)
      method = tokens.first
 
      if method == "get"
        # snapshot on the fly ???  Additive? Or replace?
      end

      if passthru_commands.include?(tokens.first) 
        return tokens
      else
        return false
      end
    end

    def passthru_commands
     ["tree", "pathways", "reload"] #, "bcome"]
    end

    def show_menu?(input)
      input == HELP_KEY
    end

    def start_message; end

  end
end
