module Bcome::Orchestration::Catalogue
  module Docker
      module Input

      def wait_for_command_input
        raw_command = wait_for_input
        process_command(raw_command) unless raw_command == "\\q"
      end

      def wait_for_input(message = command_prompt)
       ::Readline.readline("#{message}", true).squeeze('').to_s
      end

      def process_user_input_for_selection(raw_command)
        case @selection
          when :filter
            perform_filter(raw_command)
          when :shell
            get_shell_for_id(raw_command)
          when :command
            run_command_on_selection(raw_command)
          end
          show_menu
      end

      def perform_filter(parameters) 
        @filter = parameters
        list
      end

      # TODO - Refactor method, it's gone nuts
      def process_command(raw_command)
        split_command = raw_command.split(/\s+/)
        option = split_command[0]
       
        params = split_command[1..split_command.size]
        params = (params && !params.empty?) ? params.join("\s") : nil
 
        menu_opt = menu_options[@selection].select{|opt| opt[:cmd] == option }.first

        unless menu_opt
          process_user_input_for_selection(raw_command)
          wait_for_command_input
        else
          if menu_opt[:selection]
            
            if params && option == "\\s" 
              get_shell_for_id(params)
            elsif params && option == "\\f"
              perform_filter(params)  
            elsif params && option == "\\c"
              run_command_on_selection(params)
            else 
              @selection = menu_opt[:selection]
            end
 
          else
            send(menu_opt[:method])
          end
            show_menu
            wait_for_command_input
          end
        end

      end
    end
end
