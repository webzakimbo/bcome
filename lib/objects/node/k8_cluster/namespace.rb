# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Namespace < Bcome::Node::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeListHelper
    include ::Bcome::Node::KubeCommandHelper
    
    def initialize(params)
      super
      @nodes_loaded = false
    end

    def machines(skip_for_hidden = true)
      load_nodes unless nodes_loaded?
  
      resources = skip_for_hidden ? @resources.active.reject(&:hide?) : @resources.active
      set = []
      resources.each do |resource|
        resource.load_nodes unless resource.nodes_loaded?
        set << resource.machines(skip_for_hidden)
      end

      return set.flatten!
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
