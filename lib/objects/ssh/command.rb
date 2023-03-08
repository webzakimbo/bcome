# frozen_string_literal: true

module ::Bcome::Ssh
  class Command
    attr_reader :raw, :stdout, :stderr, :exit_code, :node

    def initialize(params)
      @raw = params[:raw]
      @node = params[:node]
      @exit_code = nil
      @exit_signal = nil
      @stdin = ''; @stdout = ''; @stderr = ''
    end

    def unset_node
      @node = nil
    end

    def output
      cmd_output = @stdout

      # Some processes may return output on stderr despite the command completing successfully, looking at you gitlab-runner.
      # We're going to take the approach of 'if we have output, let's show it'
      cmd_output += "\n#{@stderr}" if !@stderr.empty? 

      return "\n#{cmd_output}"
    end

    def is_success?
      exit_code.to_i == 0
    end

    def success_codes
      ['0']
    end

    attr_writer :stdout

    attr_writer :stderr

    attr_writer :exit_code

    def exit_signal(data)
      @exit_signal = data
    end
  end
end
