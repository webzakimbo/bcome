module Bcome::Orchestration::Catalogue
  module Docker
      module Container

        def re_list
          # list without a load
          pretty_container_info
        end

        def pretty_container_info
          @container_info.each do |info|
            puts "#{info[:id].informational}\t#{info[:name]}"
          end
        end

        def get_raw_containers_info
          wrap_indicator type: :basic, title: "Retrieving cluster containers", completed_title: "done" do
            begin
              do_get_raw_containers_info
              signal_success
            rescue Exception => e
              signal_failure
              raise e
            end
          end
        end

        def do_get_raw_containers_info
          @node.machines.each do |machine|
           cmd = @filter ? "#{get_raw_containers_info_cmd} | grep #{@filter}" : get_raw_containers_info_cmd
            raw_data = machine.run(cmd).first.stdout.split("\n")
            raw_data.each do |data_line|
              split_line = data_line.split("\t")
              @container_info << { id: split_line[0], name: split_line[1], cluster_node_id: machine.identifier }
            end
          end
        end

        def get_raw_containers_info_cmd
          cmd = "docker ps --format '{{.ID}}\t{{.Names}}' --filter status=running | grep -v POD"
          return cmd
        end

      end
    end
end
