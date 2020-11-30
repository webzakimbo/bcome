# frozen_string_literal: true

# note: gcloud auth only for the time being (We need to guard against NON-OAUTH for now).

# todo: this is a dynamic node (is_dynamic), and so like an inventory, cannot have any namespaces defined below it.
# todo: clean up error message when auth fails (bearer auth)
# todo: situation will arise where token is invalid. Need to re-auth
# Enshrine is_dynamic in code, and guard against putting anything below this namespace as we already for inventories

module Bcome::Node::Collection
  class Kube < ::Bcome::Node::Collection::Base

    include ::Bcome::LoadingBar::Handler
    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeGenericMenuItems

    def initialize(*params)
      super
      @container_cluster_initialized = false
      @nodes_loaded = false
    end

    def get_children_command
      "get namespaces,pods -o=custom-columns=NAME:.metadata.name,CONTAINERS:.spec.containers[*].name --all-namespaces"
    end

    def set_child_nodes
      raw_config = run_kc(get_children_command)
      items = raw_config["items"]

      namespaces_data = items.select{|item| item["kind"] == "Namespace" }
      pods_data = items.select{|item| item["kind"] == "Pod" }
      namespaces_data.pmap do |namespace_data|
        namespace_identifier = namespace_data["metadata"]["name"]
        pod_data_for_namespace = pods_data.select{|pod_data| pod_data["metadata"]["namespace"] == namespace_identifier }

        config = {
          identifier: namespace_identifier,
          raw_data: namespace_data
        }
        namespace = gke_child_node_class.new(views: config, parent: self)
        resources << namespace
        
        namespace.set_pods_from_raw_data(pod_data_for_namespace)

        ::Bcome::Node::Factory.instance.bucket[namespace.keyed_namespace] = namespace
      end
    end

    def cluster_id
      "#{cluster_name}/#{project}:#{region}"
    end

    def container_cluster_initialized?
      @container_cluster_initialized
    end  

    def cluster_name
      cluster[:name]
    end

    def region
      cluster[:region]
    end

    def project
      network[:project]
    end

    def container_cluster?
      true
    end

    def container_cluster_initialized?
      @container_cluster_initialized
    end 

    def nodes_loaded?
      @nodes_loaded 
    end

    def load_nodes
      get_cluster_credentials unless container_cluster_initialized?

      title = "Loading\s" + "GKE Cluster\s".bc_cyan + namespace.to_s.underline
      wrap_indicator type: :basic, title: title, completed_title: '' do
        @nodes_loaded = true
        set_child_nodes
        signal_success
      end
      print "\n"
    end
  
    def raw_config_data
      run_kc("get config")
    end 

    def run_kc(command)
      @k8_cluster.run_kubectl(command)
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

      wrap_indicator type: :basic, title: "Authorising\s" + "GCP\s".bc_cyan + cluster_id.underline, completed_title: 'done' do
        begin
          @k8_cluster = ::Bcome::Driver::Gcp::Gke::Cluster.new(self)
        rescue StandardError => e
          raise ::Bcome::Exception::Generic, "Could not retrieve credentials for #{cluster_id}. Failed with: #{e.message}"
        end  
      end
    end  

    def resources
      @resources ||= ::Bcome::Node::Resources::Base.new(self)
    end

    def validate!
      [:cluster_name, :region, :project].each do |required_attribute|
        raise ::Bcome::Exception::Generic, "Missing cluster configuration attribute '#{require_attribute}'" unless send(required_attribute)
      end
    end

  end
end
