# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Namespace < Bcome::Node::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeListHelper
    
    def initialize(params)
      super
      @nodes_loaded = false
    end

    def load_nodes
      set_child_nodes
      @nodes_loaded =  true
    end

    def nodes_loaded?
      @nodes_loaded
    end  

    def requires_description?
      false
    end

    def type
      "namespace"
    end

    def ingresses
      run_kc("get ingresses")
    end  

    # Run a command against every container in every active pod.
    def run(command)
      resources.active.pmap do |pod|
        pod.run(command)
      end
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

    def gke_child_node_class
      ::Bcome::Node::K8Cluster::Pod
    end

    def k8_cluster
      parent.k8_cluster
    end

  end
end
