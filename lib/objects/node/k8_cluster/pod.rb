# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Pod < Bcome::Node::K8Cluster::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeCommandHelper
    include ::Bcome::Node::KubeGenericMenuItems

    RUNNING_STATE="running".freeze

    def nodes_loaded?
      true
    end

    def description
      identifier
    end

    def list_attributes
      attribs = {
      "k8/#{type}": :identifier,
      "state": :state
      }
      attribs    
    end

    def enabled_menu_items
      (super + %i[logs tunnel]) - non_k8_menu_items
    end

    def menu_items
      base_items = super.dup
      base_items[:tunnel] = {
        description: 'Forward a Pod port to your local machine',
        group: :ssh,
        usage: "tunnel [port]"
      }
      base_items[:logs] = {
        description: 'Live tail stdout (all selected containers)',
        group: :informational
      }
      base_items
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

    def get_container_states
      # containers are either running, waiting, or terminated
      raw_cs = views[:raw_data]["status"]["containerStatuses"]
      return [] unless raw_cs

      raw_states = raw_cs.collect{|cs| cs["state"] }

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

    def reset_resources!
      @resources = ::Bcome::Node::Resources::Base.new
      set_containers
    end

    def set_containers
      raw_container_data = views[:raw_data]["spec"]["containers"]
      raw_container_data.each do |container_data|
        container_config = {
          identifier: container_data["name"],
          raw_data: container_data
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

    def update_identifier(new_identifier)
      @identifier = new_identifier
    end

    def dup_with_new_parent(new_parent)
      new_node = clone
      new_node.update_parent(new_parent)
      new_node
    end

    def update_parent(new_parent)
      @parent = new_parent
    end

    def requires_description?
      false
    end

    def type
      "pod"
    end

    def get_children_command
      "get pods"
    end

    def form_tunnel_command_for_container(local_and_remote_port)
      "port-forward #{hyphenated_identifier} #{local_and_remote_port} -n #{parent.hyphenated_identifier}"
    end

    def tunnel(local_and_remote_port)
      puts "\nForwarding localhost:#{local_and_remote_port}".informational
      puts "CTRL+C to close\n"
      get_tunnel_command = form_tunnel_command_for_container(local_and_remote_port)
      command = get_kubectl_cmd(get_tunnel_command)
      runner = ::Bcome::Command::Local.run(command)
    end

    def deployment
      get_deployment_command = "get deployment #{hyphenated_identifier} -n #{k8_namespace.hyphenated_identifier}"
      system(get_kubectl_cmd(get_deployment_command))
    end

    def logs(cmd = "")
      # We get all the logs for all our containers
      resources.active.pmap do |container|
        annotate = true
        container.logs(annotate, cmd)
      end
    end

    def get_kubectl_cmd(command)
      return k8_cluster.get_kubectl_cmd(command)
    end
 
    def gke_child_node_class
      ::Bcome::Node::K8Cluster::Container
    end

    def delegated_kubectl_cmd(command)
      command_in_context = "#{command}\s#{hyphenated_identifier}"
      parent.delegated_kubectl_cmd(command)
    end

    def run_kubectl_cmd(command)
      command_in_context = "#{command}\s#{hyphenated_identifier}"
      parent.run_kubectl_cmd(command)
    end
 
    def run_kc(command)
      command_in_context = "#{command}\s#{hyphenated_identifier}"
      parent.run_kc(command_in_context)
    end

    def k8_namespace
      parent.k8_namespace
    end

    def k8_cluster
      parent.k8_cluster
    end

  end
end
