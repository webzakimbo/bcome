# frozen_string_literal: true

## TODO - split out shared methods from POD and CRD into a base class called Resource from which thes both inherit

module Bcome::Node::K8Cluster
  class Crd < Bcome::Node::K8Cluster::Base

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

    def state
      "TODO - can we infer some sort of state?"
    end

    def kubectl
      puts "Kubectl is not available from #{type} level".warning
    end

    def reset_resources!
      @resources = ::Bcome::Node::Resources::Base.new
      set_containers
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
      binding.pry  
    end

    def get_kubectl_cmd(command)
      return k8_cluster.get_kubectl_cmd(command)
    end
 
    def delegated_kubectl_cmd(command)
      parent.delegated_kubectl_cmd(command)
    end

    def run_kubectl_cmd(command)
      parent.run_kubectl_cmd(command)
    end
 
    def run_kc(command)
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
