# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Namespace < Bcome::Node::Base

    include ::Bcome::Node::KubeHelper
    
    def initialize(params)
      super
      @nodes_loaded = false
    end

    def load
      set_child_nodes
    end

    def type
      "namespace"
    end

    def run_kc(command)
      command_in_context = append_namespace_to(command)
      parent.k8_cluster.run_kubectl(command_in_context)
    end

    def append_namespace_to(command)
      "#{command} -n #{identifier}"
    end 

    def get_children_command
      "get pods"
    end

    def gk3_child_node_description
      "pod"
    end

    def gke_child_node_class
      ::Bcome::Node::K8Cluster::Pod
    end

    def k8_cluster
      parent.k8_cluster
    end

  end
end
