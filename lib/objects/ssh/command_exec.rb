# frozen_string_literal: true

module ::Bcome::Ssh
  class CommandExec
    attr_reader :commands

    def initialize(commands)
      @commands = commands
    end

    def output_append(output_string)
      @output_string = "#{@output_string}#{output_string}"
    end

    def print_output
      print "#{@output_string}\n\n"
    end

    def execute!
      # TODO: - catch IOError: closed stream here and re-connect gracefully
      # to reproduce: open connections, and let them timeout then re-enter command (interactive mode)

      @commands.each do |command|
        node = command.node
        ssh = node.ssh_driver.ssh_connection

        begin
          ssh_exec!(ssh, command)
        rescue IOError # Typically occurs after a timeout if the session has been left idle
          node.open_ssh_connection
          ssh_exec!(ssh, command) # retry, once
        end

        output_append("\n(#{node.namespace})$".terminal_prompt + ">\s#{command.raw} (#{command.pretty_result})\n")
        output_append(command.output.to_s)
      end
      print_output unless ::Bcome::Orchestrator.instance.command_output_silenced?
    end

    def ssh_exec!(ssh, command) #  NON PTY (i.e no pseudo-terminal)
      ssh.open_channel do |channel|
        channel.exec(command.raw) do |_cha, success|
          abort "FAILED: couldn't execute command (ssh.channel.exec)" unless success

          channel.on_data do |_ch, data|
            command.stdout += data
          end

          channel.on_extended_data do |_ch, _type, data|
            command.stderr += data
          end

          channel.on_request('exit-status') do |_ch, data|
            command.exit_code = data.read_long
          end

          channel.on_request('exit-signal') do |_ch, data|
            command.exit_signal = data.read_long
          end
        end
      end
      ssh.loop
    end
  end
end
