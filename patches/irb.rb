# frozen_string_literal: true

require 'irb'
module IRB
  class << self
    # with thanks: http://stackoverflow.com/questions/4749476/how-can-i-pass-arguments-to-irb-if-i-dont-specify-programfile
    def parse_opts_with_ignoring_script(*_params)
      arg = ARGV.first
      script = $PROGRAM_NAME
      parse_opts_without_ignoring_script
      @CONF[:SCRIPT] = nil

      @CONF[:IGNORE_SIGINT] = true

      $0 = script
      ARGV.unshift arg
    end
    alias parse_opts_without_ignoring_script parse_opts
    alias parse_opts parse_opts_with_ignoring_script

    def start_session(bc_workspace, binding)
      workspace = WorkSpace.new(binding)

      IRB.conf[:PROMPT][:CUSTOM] = {
        PROMPT_N: "\e[1m:\e[m ",
        PROMPT_I: "\e[1m#{bc_workspace.irb_prompt} >\e[m ",
        PROMPT_C: "\e[1m#{bc_workspace.irb_prompt} >\e[m ",
        RETURN: "%s \n"
      }
      IRB.conf[:PROMPT_MODE] = :CUSTOM

      irb = Irb.new(workspace)

      @CONF[:IRB_RC]&.call(irb.context)
      @CONF[:MAIN_CONTEXT] = irb.context

      # Do not echo command return values
      irb.context.echo = false

      catch(:IRB_EXIT) do
        irb.eval_input
      end
    end
  end

  module ExtendCommandBundle
    class << self
      # Allow us to redefine 'quit' by preventing it getting aliased in the first place.
      def overriden_extend_object(*params)
        # Remove 'quit', as we want to write our own
        @ALIASES.delete([:quit, :irb_exit, 1])

        original_extend_object(*params)
      end
      alias original_extend_object extend_object
      alias extend_object overriden_extend_object
    end

    def quit(*_params)
      ::Bcome::Bootup.instance.close_ssh_connections
      ::Bcome::Ssh::TunnelKeeper.instance.close_tunnels
      ::Bcome::LoadingBar::PidBucket.instance.stop_all
      exit!
    end

    def back
      # Allow navigation back up a namespace tree, or 'exit' if at the highest level, or at the point of entry
      irb_exit(0)
    end
  end

  class Context
    def overriden_evaluate(*_params)

      # Allow the user to directly invoke cd path:to:namespace where
      # the input after "cd" matches the bcome breadcrumb format. This can have no conflict with user generated methods
      # or other framework hooks as 'cd' is a reserved word, and we are explicitly matching on cd path:to:node 
      if _params[0] =~ /^cd ([a-z0-9_]+(\:[a-z0-9_]+)+)$/i
        _params[0] = "cd \"#{$1}\""
      end

      if _params.last.is_a?(Hash)
        # Ruby 2.7.0 compatibility: "Using the last argument as keyword parameters is deprecated" ; hence splat the last argument
        last = _params.pop
        without_last = _params - [last]
        evaluate_without_overriden(*without_last, **last)
      else
        # previous rubies...
        evaluate_without_overriden(*_params)
      end
    rescue ::Bcome::Exception::Base => e
      puts e.pretty_display
    end

    alias evaluate_without_overriden evaluate
    alias evaluate overriden_evaluate
  end # end class Context
end # end module IRB --
