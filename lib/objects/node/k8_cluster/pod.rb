# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Pod < Bcome::Node::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeListHelper
    include ::Bcome::Node::KubeCommandHelper
    include ::Bcome::Node::KubeGenericMenuItems

    def is_event?
      raw_config_data["spec"]["containers"][0]["env"].select{|env| env["name"] == "POSTGRES_HOST" && env["value"] == "dev-ecosystem-postgres-event" }.any?
    end
  
    def load_nodes
      set_containers
      @nodes_loaded =  true
    end

    def nodes_loaded?
      @nodes_loaded
    end

    def machines(skip_for_hidden = true)
      load_nodes unless nodes_loaded?
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

    def set_containers
      raw_nodes = run_kc(get_children_command)
      raw_nodes["spec"]["containers"].each do |item_data|
        config = {
          identifier: item_data["name"],
          raw_data: item_data
        }
        resources << gke_child_node_class.new(views: config, parent: self)
      end
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
