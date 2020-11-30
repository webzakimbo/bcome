# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Namespace < Bcome::Node::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeListHelper
    include ::Bcome::Node::KubeCommandHelper
    include ::Bcome::Node::KubeGenericMenuItems
    
    def initialize(params)
      super
      @nodes_loaded = false
    end

    def machines(skip_for_hidden = true)
      resources = skip_for_hidden ? @resources.active.reject(&:hide?) : @resources.active
      set = []
      resources.each do |resource|
        set << resource.machines(skip_for_hidden)
      end

      return set.flatten!
    end

    def set_pods_from_raw_data(raw_pods_data)
      raw_pods_data.pmap do |pod_data|
        pod_identifier = pod_data["metadata"]["name"]

        namespace_config = {
          identifier: pod_identifier,
          raw_data: pod_data
        }
        pod = gke_child_node_class.new(views: namespace_config, parent: self)
        resources << pod
        pod.set_containers
        ::Bcome::Node::Factory.instance.bucket[pod.keyed_namespace] = pod
      end
      return
    end

    def nodes_loaded?
      true 
    end  

    def log
      resources.active.each do |resource|
        puts "#{resource.keyed_namespace}".bc_cyan + " / log" 
        resource.log
      end  
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
