# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Pod < Bcome::Node::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeCommandHelper
    include ::Bcome::Node::KubeGenericMenuItems

    RUNNING_STATE="running".freeze

    def is_event?
      raw_config_data["spec"]["containers"][0]["env"].select{|env| env["name"] == "POSTGRES_HOST" && env["value"] == "dev-ecosystem-postgres-event" }.any?
    end
  
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

    def state
      "#{running_status}\s" + container_states.sort.uniq.join(" | ")
    end
   
    def container_states
      @container_states ||= get_container_states
    end

    def number_running
      container_states.select{|cs| cs == RUNNING_STATE }.size
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
          states << "#{RUNNING_STATE}".upcase
        else
          states << "#{cs[top_level_status]["reason"]}".upcase
        end
      end
      states
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

    def log
      system(k8_cluster.get_kubectl_cmd(log_command_suffix))
    end

    def log_command_suffix
      "logs -n #{k8_namespace.hyphenated_identifier} #{hyphenated_identifier} --previous"
    end
 
    def gke_child_node_class
      ::Bcome::Node::K8Cluster::Container
    end
 
    def run_kc(command)
      command_in_context = "#{command}\s#{hyphenated_identifier}"
      parent.run_kc(command_in_context)
    end

    def k8_namespace
      parent
    end

    def k8_cluster
      parent.k8_cluster
    end

  end
end
