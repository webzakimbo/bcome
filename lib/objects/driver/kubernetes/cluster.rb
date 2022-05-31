module ::Bcome::Driver::Kubernetes
  class Cluster

    NAME_PREFIX="bcome".freeze

    attr_reader :config 

    def initialize(node)
      raise "Invalid collection class #{node.class} for #{self.class}" unless node.is_a?(expected_collection_class)
      @node = node
      register_cluster unless registered?
    end  

    def registered?
      return false # flex point for EKS. Overriden in GKE.
    end

    def reauthorize!
      puts "Re-authenticating with cluster".informational
      # trigger a re-auth
      network_driver.authorize(true)

      # update our kubectl conf with the newly acquired access token
      set_cluster_access_token
    end

    def register_cluster_context
      run_kubectl_config("config set-context #{name} --cluster=#{cluster_name} --user=#{username}")
    end

    def cluster_name
      @node.cluster_name
    end

    def username
      raise "Should be overidden"
    end

    def register_cluster
      raise "Should be overidden"
    end

    def expected_collection_class
      raise "Should be overriden"
    end

    def set_as_external_context(namespace = nil)
      register_cluster_context(namespace)
     
      puts "" 
      reauthorize!

      context_name = namespace ? "#{name}_#{namespace.identifier}" : name
      run_kubectl_config("config use-context #{context_name}")
    end

    def server
      "https://#{endpoint}"
    end

    def remote_name
      @node.cluster_name
    end

    def running?
      status == "RUNNING"
    end

    ##############
    ## COMMANDS ##
    ##############

    def delegated_kubectl_cmd(command)
      command_runner = runner(command, :no_json, :command_call)
      return command_runner.run_hand_off
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
  end
end
