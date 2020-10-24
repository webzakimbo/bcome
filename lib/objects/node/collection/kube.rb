# frozen_string_literal: true

# todo - validate cluster data
# todo - use bcome's auth via service account route: expecting user to login in separately is a pain, and breaks the pattern


# things that need to happen
# 1. authentication with gcloud / service_account (Or oauth)
# 2. get cluster credentials [optional: do if can't auth for 3]
# 3. set the current cluster (using the kubectl config?)

# Layers of abstraction
  # 1. setting nodes (namespace, pods, containers) and allowing exec could be a pure ruby thing. I.e. we use the API
  # This would be cleaner than parsing kubectl

  # 2. Each node has access to a shell function, where we can kubectl (within the context of where we already are)
  # Can we pass kubectl the credentials which we've acquired from (2 - things that need to happen). above  

  # 3. In-built methods (like 'ssh', which is really exec, 'run' etc) 
  # Menu is different for a Kube container down that the server menu. Some similarities, but reduced command set.

# holy grail
# a 'run' over a server AND a container at the same time.

module Bcome::Node::Collection
  class Kube < ::Bcome::Node::Collection::Base

    GCLOUD_BINARY = "gcloud".freeze

    include ::Bcome::LoadingBar::Handler

    def initialize(*params)
      super
      @container_cluster_initialized = false
    end

    def container_cluster?
      true
    end

    def container_cluster_initialized?
      @container_cluster_initialized
    end 

    def init_container_cluster
      ## Validate our service account
      network_driver.authorize
      get_cluster_credentials
    end  

    def get_cluster_credentials
      binding.pry

      #wrap_indicator type: :basic, title: "authorising\s".informational + cluster_id.bc_orange, completed_title: 'done' do
      #  begin
      #    validate!
      #    command_result = ::Bcome::Command::Local.run(authorize_namespace_command)
      #    raise command_result.stderr unless command_result.is_success?
      #    @container_cluster_initialized = true
      #  rescue Exception => e
      #    raise ::Bcome::Exception::Generic, "Could not retrieve credentials for #{cluster_id}. Failed with: #{e.message}"
      #  end
      #end
    end  

    def authorize_namespace_command
      ## Getting credentials: todo: needs to be via a set service account
      "#{GCLOUD_BINARY} container clusters get-credentials #{cluster_name} --region #{region} --project #{project}"
    end

    def resources
      []
    end

    def validate!
      [:cluster_name, :region, :project].each do |required_attribute|
        raise "Missing cluster configuration attribute '#{require_attribute}'" unless send(required_attribute)
      end
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

  end
end
