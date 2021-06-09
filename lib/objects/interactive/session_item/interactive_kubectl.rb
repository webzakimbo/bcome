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

    def show_menu?(input)
      input == HELP_KEY
    end

    def start_message; end

  end
end
