# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Pod < Bcome::Node::K8Cluster::Child

    RUNNING_STATE="running".freeze

    def is_job?
      # TODO - there must be a better way ?
      raw_data["metadata"]["ownerReferences"].collect{|refs| refs["kind"]}.include?("Job")
    end

    def list_attributes
      attribs = {
      "k8/#{type}": :identifier,
      "state": :state
      }
      attribs    
    end

    def enabled_menu_items
      (super + %i[logs tunnel]) 
    end

    def menu_items
      base_items = super.dup

      base_items[:tunnel] = {
        description: 'Forward a Pod port to your local machine',
        group: :kubernetes,
        usage: "tunnel [port]"
      }

      base_items[:interactive] = {
        description: 'Execute commands against all containers in this pod',
        group: :ssh,
      }

      base_items
    end

    def pathway_data(scheme, service_port)
      map = {}
      if resources.any?
        map = {}
        resources.each do |resource|
          map.merge!({
            identifier => { "#{scheme}://#{resource.identifier}:#{service_port}" => nil }
          })
        end
      else
        return { "X".error.bold => nil }
      end
      return map
    end

    def focus_breadcrumb
      "containers"
    end

    def resources
      @resources ||= ::Bcome::Node::Resources::PodK8.new
    end

    def services
      @services ||= parent.crds["Service"].select{|s| s.pod == self }
    end

    def state
      "#{running_status}\s" + container_states.sort.uniq.join(" | ")
    end
   
    def container_states
      @container_states ||= get_container_states
    end

    def number_running
      container_states.select{|cs| cs == RUNNING_STATE.upcase }.size
    end

    def running_status
      "[#{number_running}/#{resources.size}]"
    end

    def container_ids
      container_status_data.collect{|status_data| status_data["containerID"] }
    end

    def container_status_data
      c = views[:raw_data]["status"]["containerStatuses"].nil? ? [] : views[:raw_data]["status"]["containerStatuses"]
      i = views[:raw_data]["status"]["initContainerStatuses"].nil? ? [] : views[:raw_data]["status"]["initContainerStatuses"] 
      return c + i
    end

    def get_container_states
      # containers are either running, waiting, or terminated
      return [] unless container_status_data

      raw_states = container_status_data.collect{|cs| cs["state"] }

      states = []
      raw_states.each_with_index do |cs, index|
        top_level_status = cs.keys.first
        if top_level_status == RUNNING_STATE
          states << RUNNING_STATE.upcase
        else
          states << "#{cs[top_level_status]["reason"]}".upcase
        end
      end
      states
    end

    def set_child_nodes
      set_containers
    end  

    def all_container_data
      c = spec["containers"].nil? ? [] : spec["containers"]
      i = spec["initContainers"].nil? ? [] : spec["initContainers"]
      return c + i
    end

    def spec
      views[:raw_data]["spec"]
    end

    def set_containers
      states = get_container_states

      all_container_data.each_with_index do |container_data, index|
        container_config = {
          identifier: container_data["name"],
          raw_data: container_data.merge({ state: states[index] })
        }

        container = gke_child_node_class.new(views: container_config, parent: self)
        resources << container
        ::Bcome::Node::Factory.instance.bucket[container.keyed_namespace] = container
      end
      return
    end

    def machines(skip_for_hidden = true)
      resources = skip_for_hidden ? @resources.active.reject(&:hide?) : @resources.active
      return resources.collect(&:machines).flatten
    end

    def get_children_command
      "get pods"
    end

    def form_tunnel_command_for_container(local_and_remote_port)
      "port-forward #{hyphenated_identifier} #{local_and_remote_port} -n #{k8_namespace.hyphenated_identifier}"
    end

    def tunnel(local_and_remote_port)
      puts "\nForwarding localhost:#{local_and_remote_port}".informational
      puts "CTRL+C to close\n"
      get_tunnel_command = form_tunnel_command_for_container(local_and_remote_port)
      #puts get_tunnel_command
      command = get_kubectl_cmd(get_tunnel_command)
      runner = ::Bcome::Command::Local.run(command)
      return runner
    end

    def deployment
      get_deployment_command = "get deployment #{hyphenated_identifier} -n #{k8_namespace.hyphenated_identifier}"
      system(get_kubectl_cmd(get_deployment_command))
    end

    def logs(*params)
      # Get all logs for all containers (i.e. previously failed containers too)
      all_logs_command = "logs #{hyphenated_identifier} --follow --all-containers -n #{k8_namespace.hyphenated_identifier}"

      annotated_log_command = "#{all_logs_command} | while read line ; do echo \"#{namespace.terminal_prompt} $line\" ; done"

      system(get_kubectl_cmd(annotated_log_command))
    end

    def gke_child_node_class
      ::Bcome::Node::K8Cluster::Container
    end

  end
end
