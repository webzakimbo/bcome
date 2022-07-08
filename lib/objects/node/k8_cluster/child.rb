# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Child < Bcome::Node::K8Cluster::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeCommandHelper
    include ::Bcome::Node::KubeGenericMenuItems
    include ::Bcome::Node::KubeResourceCommonAccessors

    def nodes_loaded?
      true
    end

    def description
      identifier
    end

    def list_attributes
      { "k8/#{type}": :identifier }
    end

    def machines(skip_for_hidden = true)
      resources = skip_for_hidden ? @resources.active.reject(&:hide?) : @resources.active
      return resources.collect(&:machines).flatten
    end

    def logs(cmd = "")
      resources.active.pmap do |pod|
        pod.logs(cmd)
      end
    end

    def enabled_menu_items
      super - non_k8_menu_items
    end

    def kubectl
      puts "Kubectl is not available at this level".warning
    end

    def reset_resources!
      @resources = ::Bcome::Node::Resources::Base.new
      set_child_nodes if respond_to?(:set_child_nodes)
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
      raw_data["kind"].downcase
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

    def k8_namespace
      parent.k8_namespace
    end

    def k8_cluster
      parent.k8_cluster
    end
  end
end
