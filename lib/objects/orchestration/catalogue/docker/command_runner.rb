module Bcome::Orchestration::Catalogue
  module Docker
      module CommandRunner

        def get_shell_for_id(id)
          shell_info = @container_info.select{|cont| cont[:id] == id }.first
          unless shell_info
            puts "Could not find container matching id '#{id}'".warning
          else
            machine = @node.machines.flatten.select{|m| m.identifier == shell_info[:cluster_node_id] }.first
            machine.pseudo_tty "docker exec -it #{id} /bin/sh"
          end
        end

        def run_command_on_selection(command)
          puts "\n"
          @container_info.each do |shell_info|
            machine = @node.machines.flatten.select{|m| m.identifier == shell_info[:cluster_node_id] }.first
            container_id = shell_info[:id]
            puts "#{shell_info[:name]}".bc_cyan
            machine.pseudo_tty "docker exec -it #{shell_info[:id]} #{command}"
            puts "\n"
          end
        end

      end
    end
end
