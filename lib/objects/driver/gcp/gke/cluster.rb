module ::Bcome::Driver::Gcp::Gke
  class Cluster

    include ::Bcome::Driver::Gcp::Gke::ClusterInit
    include ::Bcome::Driver::Gcp::Gke::ClusterAttributes  

    attr_reader :config 

    def initialize(node)
      raise "Invalid collection class for #{self.class}" unless node.is_a?(::Bcome::Node::Collection::Kube)
      @node = node
      register_cluster
    end  

    def register_cluster
      register_cluster_in_config
      register_cluster_certificate_in_config
      register_user_in_config
      register_cluster_context
    end
 
    ## The config for this particular cluster --
    def config 
      @config ||= get_config
    end

    def delegated_kubectl_cmd(command)
      command_runner = runner(command, :no_json, :command_call)
      command_runner.run_hand_off
    end

    def get_kubectl_cmd(command)
      command_runner = runner(command, :no_json, :command_call)
      return command_runner.full_command
    end

    def run_kubectl_cmd(command)
      command_runner = runner(command, :no_json, :command_call)
      command_runner.run_local
      return command_runner
    end

    def run_kubectl_config(command)
      command_runner = runner(command, :no_json, :config_call)
      return command_runner.data
    end
 
    def run_kubectl(command)
      command_runner = runner(command, :as_json, :cluster_call)
      return command_runner.data
    end

    def runner(command_suffix, output, call_type)
      ::Bcome::K8Cluster::CommandRunner.new(self, command_suffix, output, call_type)
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
