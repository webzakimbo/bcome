module Bcome::Orchestration::Catalogue
  module Docker
      module Menu

        def show_menu
          puts "\n\n"

          if [:command, :shell].include?(@selection)
            re_list
            puts "\n"
          end

          menu_options[@selection].each do |command_set|
            puts "#{command_set[:cmd].instructional}\s#{command_set[:desc]}"
          end
          puts "\n"
        end

        def menu_options
          { default: [
              { cmd: "\\l", desc: "list containers", method: :list },
              { cmd: "\\f", desc: "filter list", selection: :filter  },
              { cmd: "\\s", desc: "shell mode", selection: :shell  },
              { cmd: "\\c", desc: "run command", selection: :command },
              { cmd: "\\q", desc: "quit" },
              { cmd: "\\r", desc: "reset filter", method: :reset_filter }
            ],
            filter: [
              { cmd: "\\r", desc: "reset filter", method: :reset_filter },
              { cmd: "\\b", desc: "back", method: :back_to_default },
              { cmd: "\\q", desc: "quit" }
            ],
            shell: [
              { cmd: "\\b", desc: "back", method: :back_to_default },
              { cmd: "\\q", desc: "quit" }
            ],
            command: [
              { cmd: "\\b", desc: "back", method: :back_to_default },
              { cmd: "\\q", desc: "quit" }
            ],
          }
        end

      end
    end
end
