# frozen_string_literal: true

# note: gcloud auth only for the time being (We need to guard against NON-OAUTH for now).

# todo: this is a dynamic node (is_dynamic), and so like an inventory, cannot have any namespaces defined below it.
# todo: clean up error message when auth fails (bearer auth)
# Enshrine is_dynamic in code, and guard against putting anything below this namespace as we already have for standard inventories

module Bcome::Node::K8Cluster::Collection
  class Base < ::Bcome::Node::Collection::Base

    include ::Bcome::InteractiveKubectl
    include ::Bcome::LoadingBar::Handler
    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::K8Cluster::HelmWrap
    include ::Bcome::InteractiveHelm
    include ::Bcome::Node::K8Cluster::PathwayRender

    def initialize(*params)
      super
      @container_cluster_initialized = false
      @nodes_loaded = false
    end

    def interactive
      kubectl
    end

    def is_describable?
      false
    end

    def logs(cmd = "")
      resources.active.pmap do |pod|
        pod.logs(cmd)
      end
    end

    def set_child_nodes
      ::Bcome::Node::Collection::Snapshot.do(self)
    end

    def enabled_menu_items
      (super + %i[config lsr reload]) - non_k8_menu_items
    end

    def ingresses
      resources.active.collect{|resource| resource.crds["Ingress"] }.flatten.compact
    end

    def menu_items
      base_items = super.dup

      base_items[:lsr] = {
        description: 'Reload from remote & list',
        group: :informational
      }

      base_items[:config] = {
        description: 'Display the k8 configuration for this node',
        group: :informational
      }

      base_items[:reload] = {
        description: 'Reload all resources',
        group: :informational
      }

      base_items
    end

    def cluster_id
      raise "Should be overidden"
    end

    def container_cluster_initialized?
      @container_cluster_initialized
    end  

    def cluster_name
      cluster[:name]
    end

    def container_cluster?
      true
    end

    def nodes_loaded?
      @nodes_loaded 
    end

    def load_nodes
      get_cluster_credentials unless container_cluster_initialized?

      @nodes_loaded = true
      set_child_nodes
      print "\n"
    end
  
    def reload
      do_reload
      puts "\n\nDone. Hit 'ls' to see the refreshed inventory.\n".informational
    end

    def do_reload
      resources.unset!
      load_nodes
    end

    def raw_config_data
      run_kc("get config")
    end 

    def delegated_kubectl_cmd(command)
      @k8_cluster.delegated_kubectl_cmd(command)
    end

    def run_kubectl_cmd(command)
      @k8_cluster.run_kubectl_cmd(command)
    end

    def run_kc(command)
      @k8_cluster.run_kubectl(command)
    end 

    def kubectl_context
      identifier
    end

    def gke_child_node_class
      ::Bcome::Node::K8Cluster::Namespace
    end

    def k8_cluster
      @k8_cluster 
    end

    def get_cluster_credentials
      # Validate the user's configuration is complete
      validate!

      # Ensure that we have kubectl installed and in PATH.
      # We'll do this early enough
      ::Bcome::EnsureBinary.do(::Bcome::K8Cluster::CommandRunner::KUBECTL_BINARY)

      do_get_credentials
    end  

    def do_get_credentials
      raise "Should be overriden"
    end 

    def resources
      @resources ||= ::Bcome::Node::Resources::Base.new(self)
    end

    def required_attributes
      raise "Should be overidden"
    end

    def validate!
      required_attributes.each do |required_attribute|
        raise ::Bcome::Exception::Generic, "Missing cluster configuration attribute '#{required_attribute}'" unless send(required_attribute)
      end
    end
  end
end
