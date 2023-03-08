# frozen_string_literal: true

module Bcome::Interactive::SessionItem
  class AdHocCli < ::Bcome::Interactive::SessionItem::Base

    END_SESSION_KEY = '\\q'
    HELP_KEY = '\\?'

    def initialize(*params)
      super
      @working_dir = nil
      validate
      ::Bcome::Orchestrator.instance.tail_all_command_output!(node)
    end  

    def do
      run_cli_command(startup_command) if startup_command

      puts "\n#{cli_description.bc_yellow}"
      puts "\nEnter your commands after the #{cli_command_prefix.informational} prompt."

      show_menu
      puts ''
      action
    end

    def action
      input = get_input

      return if exit?(input)

      if show_menu?(input)
        show_menu
        print "\n"
      else
        run_cli_command(input)
      end

      action
    end

    def show_menu
      info = "\n\\? this message\n\\q to quit".informational
      puts "#{info}\n"
    end

    def run_cli_command(input)
      command = run_as_user ? "sudo -u #{run_as_user} sh -c '#{cli_command_prefix} #{input}'" : "#{cli_command_prefix} #{input}"
      node.run command
    end

    def start_message; end

    def terminal_prompt
      return "#{bcome_identifier}\s#{cli_command_prefix.bc_cyan}\s"
    end

    def exit?(input)
      input == END_SESSION_KEY
    end

    def show_menu?(input)
      input == HELP_KEY
    end

    def run_as_user
      @init_data[:run_as_user]
    end 

    def startup_command
      @init_data[:startup_command]
    end

    def cli_command_prefix
      @init_data[:cli_command_prefix]
    end

    def cli_description
      @init_data[:cli_description]
    end
 
    def validate
      [:cli_description, :cli_command_prefix].each do |expected_attr|
        raise ::Bcome::Exception::Generic, "Missing configuration parameter '#{expected_attr}'" unless send(expected_attr)
      end
    end 

  end
end
