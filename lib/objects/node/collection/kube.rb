# frozen_string_literal: true

# note: gcloud auth only for the time being (We need to guard against NON-OAUTH for now).

# todo: this is a dynamic node (is_dynamic), and so like an inventory, cannot have any namespaces defined below it.
# todo: clean up error message when auth fails (bearer auth)
# todo: situation will arise where token is invalid. Need to re-auth
# Enshrine is_dynamic in code, and guard against putting anything below this namespace as we already for inventories

module Bcome::Node::Collection
  class Kube < ::Bcome::Node::Collection::Base

    GCLOUD_BINARY = "gcloud".freeze
    KUBECTL_BINARY = "kubectl".freeze
 
    include ::Bcome::LoadingBar::Handler

    def initialize(*params)
      super
      @container_cluster_initialized = false
      @nodes_loaded = false
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

    def kubectl_command_prefix
      "#{KUBECTL_BINARY}"
    end

    def ontainer_cluster_initialized?
      @container_cluster_initialized
    end 

    def nodes_loaded?
      @nodes_loaded 
    end

    def load_nodes
      get_cluster_credentials unless container_cluster_initialized?

      @nodes_loaded = true
      set_namespaces
      print "\n"
    end

    def set_namespaces
      # We delegate everything to kubectl. We're a wrapper, rather than re-implementing what is a massive wheel.
      #::Bcome::EnsureBinary.do(GCLOUD_BINARY)


        title = 'Loading' + "\sGke".bc_orange.bold + "\s" + namespace.to_s.underline
        wrap_indicator type: :basic, title: title, completed_title: '' do
     

          # HERE: Lookup call to Kubectl.
	  # TODO:  Class to execute kubectl command and retrieve json
          # We only deal in Json

          # We're store the whole JSON result and mark this as "nodes_loaded" or something
          # then, a reload will re-load and re-create the structure (from this point onwwards - can do the same 
          # for pods and containers.
          # WE'LL ABSTRACT THIS INTO A MODULE so same functionality can be pasted into Pods & Container
          # ALWAYS store whole JSON. Make it accessible and then can be used to enrich the data we then show.

          [ { identifier: "foo", description: "A foo" } ].each do |namespace_data|
            resources << ::Bcome::Node::K8Cluster::Namespace.new(views: namespace_data, parent: self)
          end
          signal_success
       end
    end

    def k8_cluster
      @k8_cluster 
    end

    def get_cluster_credentials
      # Validate the user's configuration is complete
      validate!

      # Ensure that we have kubectl installed and in PATH.
      # We'll do this early enough
      ::Bcome::EnsureBinary.do(KUBECTL_BINARY)

      wrap_indicator type: :basic, title: "authorising\s".informational + cluster_id.bc_orange, completed_title: 'done' do
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
