module Bcome::Orchestration::Catalogue
  module Docker
      module TailContainer

        def tail_container_logs(id)
          shell_info = @container_info.select{|cont| cont[:id] == id }.first
          unless shell_info
            puts "Could not find container matching id '#{id}'".warning
          else
            machine = @node.machines.flatten.select{|m| m.identifier == shell_info[:cluster_node_id] }.first
            machine.pseudo_tty "docker logs -t #{id} --follow"
          end
        end
      end
    end
end
