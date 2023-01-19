# frozen_string_literal: true

require 'irb'

module IRB
  class << self
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
        PROMPT_I: "#{bc_workspace.irb_prompt}\s",
        PROMPT_C: "#{bc_workspace.irb_prompt}\s",
        RETURN: "%s \n"
      }
      IRB.conf[:PROMPT_MODE] = :CUSTOM

      IRB.conf[:USE_AUTOCOMPLETE] = false # To be re-introduced when we can inject just what we want

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
      # Allow us to redefine 'quit' and 'ls'  by preventing them getting aliased in the first place.
      def overriden_extend_object(*params)
        # Remove 'quit', as we want to write our own
        @ALIASES.delete([:quit, :irb_exit, 1])
        @ALIASES.delete([:ls, :irb_ls, 0])
        original_extend_object(*params)
      end
      alias original_extend_object extend_object
      alias extend_object overriden_extend_object
    end

    def quit(*_params)
      ::Bcome::Bootup.instance.starter.clean_up
      exit!
    end

    def back
      # Allow navigation back up a namespace tree, or 'exit' if at the highest level or at the point of entry
      if context.has_parent?
        ::Bcome::Workspace.instance.set(current_context: context.bcome_node, context: context.parent)
      else
        quit
      end
    end
  end

  class Context
    def overriden_evaluate(*_params)
      _params[0] = ::InputParser.new(_params[0], bcome_node).parse

      if _params.last.is_a?(Hash)
        # Ruby 2.7.0 compatibility: "Using the last argument as keyword parameters is deprecated" ; hence splat the last argument
        last = _params.pop
        without_last = _params - [last]
        eval_result = evaluate_without_overriden(*without_last, **last)
      else
        # previous rubies...
        eval_result = evaluate_without_overriden(*_params)
      end

      return eval_result
    rescue ::Bcome::Exception::Base => e
      puts e.pretty_display
    end

    alias evaluate_without_overriden evaluate
    alias evaluate overriden_evaluate

    def bcome_node
      IRB.conf[:MAIN_CONTEXT].workspace.main
    end 

    def parent
      bcome_node.parent
    end

    def has_parent?
      !parent.nil?
    end 
  end # end class Context
end # end module IRB --
