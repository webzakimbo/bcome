# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Pod < Bcome::Node::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeListHelper
  
    def load_nodes
      set_containers
      @nodes_loaded =  true
    end

    def nodes_loaded?
      @nodes_loaded
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

    # Run a command against every container in the pod
    def run(command)
      # todo: output which node we're running the command for

      resources.active.pmap do |container|
        container.run(command)
      end      
    end

    def type
      "pod"
    end

    def get_children_command
      "get pods"
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
