# frozen_string_literal: true

# note: gcloud auth only for the time being.

# todo:  this is a dynamic node (is_dynamic), and so like an inventory, cannot have any namespaces defined below it.
# Enshrine is_dynamic in code, and guard against putting anything below this namespace as we already for inventories

module Bcome::Node::Collection
  class Kube < ::Bcome::Node::Collection::Base

    # todo - ensure these are in PATH
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

    def container_cluster_initialized?
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
      ::Bcome::EnsureBinary.do(GCLOUD_BINARY)


      title = 'Loading' + "\sCACHE".bc_orange.bold + "\s" + namespace.to_s.underline
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

    def get_cluster_credentials
      # Todo: we expect a gcloud auth login to have occured...
   
      ## Perform an Oauth and get a token 

      network_driver.authorize




      # get the cluster data using the call poced in call.sh
  
      # then
      # read this: https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
      # aim to construct one cluster config per cluster collection namespace
      # we can prepend the call to kubectl with the path to this config.
      # Failing that, we'll use one file

      # GOAL: We wrap kubectl, but we do not need to use gcloud (and so need a separate login via gcloud auth login)
      # The data from call.sh gives us a wealth of metadata that we can use to enrich the collection namespace itself.

      ::Bcome::EnsureBinary.do(KUBECTL_BINARY)



      ## PASS access token to gcloud?? That way. OAUTH is VIA THE APP


    

      # this is effectively 'pull down the Kubectl credentials from GCP'.
      wrap_indicator type: :basic, title: "authorising\s".informational + cluster_id.bc_orange, completed_title: 'done' do
        begin
          validate!
          command_result = ::Bcome::Command::Local.run(authorize_namespace_command)
          raise command_result.stderr unless command_result.is_success?
          @container_cluster_initialized = true
         rescue Exception => e
          raise ::Bcome::Exception::Generic, "Could not retrieve credentials for #{cluster_id}. Failed with: #{e.message}"
        end
      end
    end  

    def resources
      @resources ||= ::Bcome::Node::Resources::Base.new(self)
    end

    def authorize_namespace_command
      "#{GCLOUD_BINARY} container clusters get-credentials #{cluster_name} --region #{region} --project #{project}"
    end

    def validate!
      [:cluster_name, :region, :project].each do |required_attribute|
        raise "Missing cluster configuration attribute '#{require_attribute}'" unless send(required_attribute)
      end
    end

  end
end
