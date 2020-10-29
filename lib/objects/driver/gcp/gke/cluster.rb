module ::Bcome::Driver::Gcp::Gke
  class Cluster

    include ::Bcome::Driver::Gcp::Gke::ClusterInit
    include ::Bcome::Driver::Gcp::Gke::ClusterAttributes  

    attr_reader :config 

    def initialize(node)
      raise "Invalid collection class for #{self.class}" unless node.is_a?(::Bcome::Node::Collection::Kube)
      @node = node
      register_cluster_in_config
      register_cluster_certificate_in_config
      register_user_in_config
    end  

    ## The config for this particular cluster --
    def config 
      @config ||= get_config
    end

    def run_kubectl_config(command)
      kubectl_exec(command, :no_json, :config_call)
    end
 
    def run_kubectl(command)
      kubectl_exec(command, :as_json, :cluster_call)
    end

    def kubectl_exec(command_suffix, output, is_config)
      result = ::Bcome::K8Cluster::CommandRunner.exec(self, command_suffix, output, is_config)
      return result
    end

    def network_driver
      @node.network_driver
    end

    private

    def get_config
      ::Bcome::Driver::Gcp::ApiClient::Request.do(URI(get_config_url), @node)
    end

    def get_config_url
      "https://container.googleapis.com/v1/projects/#{@node.project}/locations/#{@node.region}/clusters/#{@node.cluster_name}?alt=json"
    end  
  end
end
