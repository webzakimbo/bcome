module Bcome::Orchestration::Catalogue
  module Docker
      module Prompt

        def command_prompt
          unfiltered = "#{prompt_prefix}#{prompt_suffix}"
          whole = @filter ? "(filter:#{@filter})".bc_cyan + "\s#{unfiltered}" : unfiltered
          return whole
        end

        def prompt_prefix
          case @selection
          when :default
            "choose an option"
          when :filter
            "set filter".informational
          when :shell
            "enter container id".informational
          when :command
            "enter command".bc_red
          end
        end

        def prompt_suffix
          ">\s"
        end

      end
    end
end
