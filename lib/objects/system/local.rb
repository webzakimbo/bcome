# frozen_string_literal: true

module Bcome::System
  class Local

    include ThreadSafeSingleton

    def initialize
      @k8_view = nil
    end

    def execute_command(raw_command, print_out_command = false)
      puts "\n> #{raw_command}".bc_blue + "\n" if print_out_command

      local_command = command(raw_command)
      if local_command.failed? && !in_console_session?
        # we fail fast if we're not in a console session
        raise Bcome::Exception::FailedToRunLocalCommand, "#{raw_command}. Error: " + local_command.stderr
      end

      local_command
    end

    def k8_view=(view)
      @k8_view = view
    end

    def in_k8_view?(view_name)
      return false unless @k8_view
      return @k8_view.name == view_name
    end

    def in_default_k8_view?
      @k8_view.nil?
    end

    def in_console_session?
      ::Bcome::Workspace.instance.console_set?
    end

    def local_user
      result = command('whoami')
      result.stdout =~ /(.+)\n/
      Regexp.last_match(1)
    end

    def command(raw_command)
      ::Bcome::Command::Local.run(raw_command)
    end
  end
end
