# frozen_string_literal: true

module Bcome::Interactive::SessionItem
  class TransparentSsh < ::Bcome::Interactive::SessionItem::Base
    END_SESSION_KEY = '\\q'
    HELP_KEY = '\\?'
    LIST_KEY = '\\l'
    CHANGE_WD = '\\cwd'
    UNSET_WD  = '\\uwd'
    DANGER_CMD = "rm\s+-r|rm\s+-f|rm\s+-fr|rm\s+-rf|rm"

    def initialize(*params)
      super
      @working_dir = nil
    end  


    def machines
      skip_for_hidden = true
      node.server? ? [node] : node.machines(skip_for_hidden)
    end

    def do
      puts ''
      open_ssh_connections
      puts "INTERACTIVE COMMAND SESSION".underline
      show_menu
      puts ''
      list_machines
      action
    end

    def action
      input = get_input

      return if exit?(input)

      if show_menu?(input)
        show_menu
        print "\n"
      elsif list_machines?(input)
        list_machines
      elsif command_may_be_unwise?(input)
        handle_the_unwise(input)
      elsif change_wd?(input)
        change_wd
      elsif unset_wd?(input)
        unset_wd
      else 
        execute_on_machines(input)
      end
      action
    end

    def show_menu
      warning = "\nCommands entered here will be executed on" + "\severy\s".warning + "machine in your selection. \n\nUse with caution or hit \\q if you're unsure what this does."
      info = "\n\n\\l list machines\n\\cwd change working directory\n\\uwd unset working directory\n\\? this message\n\\q to quit".informational
      puts warning + "#{info}\n"
    end

    def handle_the_unwise(input)
      execute_on_machines(input) if prompt_for_confirmation('Command may be dangerous to run on all machines. Are you sure you want to proceed? [Y|N] > '.error)
    end

    def command_may_be_unwise?(input)
      input =~ /#{DANGER_CMD}/
    end

    def prompt_for_confirmation(message)
      answer = get_input(message)
      prompt_for_confirmation(message) unless %w[Y N].include?(answer)
      answer == 'Y'
    end

    def start_message; end

    def terminal_prompt
      preamble = "enter a command"
      return @working_dir ? "enter a command (working dir:\s#{@working_dir})>\s" : "#{preamble}>\s"
    end

    def exit?(input)
      input == END_SESSION_KEY
    end

    def show_menu?(input)
      input == HELP_KEY
    end

    def list_machines?(input)
      input == LIST_KEY
    end

    def change_wd?(input)
      input == CHANGE_WD
    end

    def unset_wd?(input)
      input == UNSET_WD
    end

    def open_ssh_connections
      ::Bcome::Ssh::Connector.connect(node, show_progress: true)
    end

    def close_ssh_connections
      node.close_ssh_connections
    end

    def indicate_failed_nodes(unconnected_nodes)
      unconnected_nodes.each do |node|
        puts "\s\s - #{node.namespace}"
      end
    end

    def list_machines
      puts "\n"

      unless machines.any?
        puts "No machines in selection\n".informational
        return
      end

      puts "Machines\n".underline.informational
      machines.each do |machine|
        puts "- #{machine.namespace}"
      end
      puts "\n"
    end

    def change_wd
      path = get_input("Enter a new working directory path>\s")
      if path =~ /(\/.+\/?)+/
        @working_dir = path
      else
        puts "\nInvalid file path format '#{path}'\n".error
      end
    end

    def unset_wd
      @working_dir = nil
    end

    def execute_on_machines(user_input)
      user_input = @working_dir ? "cd #{@working_dir} && #{user_input}" : user_input

      machines.pmap do |machine|
        begin
          machine.run(user_input)
        rescue IOError => e
          puts "Reopening connection to\s".informational + machine.identifier
          machine.reopen_ssh_connection ## TODO - doesn't make sense for containers, need a k8 specific version of interactive console
          machine.run(user_input)
        rescue Exception => e
          puts "Error connecting to #{machine.identifier} (#{e.message})".error
        end
      end
    end
  end
end
