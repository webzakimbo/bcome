# frozen_string_literal: true

# note: gcloud auth only for the time being.

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
      title = 'Loading' + "\sCACHE".bc_orange.bold + "\s" + namespace.to_s.underline
        wrap_indicator type: :basic, title: title, completed_title: '' do
     

          # HERE: Lookup call to Kubectl.
          [ { identifier: "foo", description: "A foo" } ].each do |namespace_data|
            resources << ::Bcome::Node::K8Cluster::Namespace.new(views: namespace_data, parent: self)
          end
          signal_success
       end
    end

    def get_cluster_credentials
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
