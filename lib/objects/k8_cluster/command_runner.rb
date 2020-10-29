module Bcome::K8Cluster
  class CommandRunner

    KUBECTL_BINARY = "kubectl".freeze
    BCOME_K8_CONFIG_FILE_PATH = ".kubectl/conf".freeze

    class << self
      def exec(cluster, command_suffix, output, is_config)
        runner = new(cluster, command_suffix, output, is_config)
        return runner.data
      end
    end
 
    def initialize(cluster, command_suffix, output, is_config)
      @command_suffix = command_suffix
      @output = output
      @cluster = cluster
      @is_config = is_config == :config_call
    end

    def as_json?
      @output == :as_json
    end

    def full_command
      "#{KUBECTL_BINARY}#{add_access_token_if_necessary}--kubeconfig=#{BCOME_K8_CONFIG_FILE_PATH}#{target_cluster_if_necessary}#{@command_suffix}#{ as_json? ? " -o json" : ""}"
    end

    def add_access_token_if_necessary
      # If we're not making a config call (a call to configure kubectl
      @is_config ? "\s" : "\s--token=#{access_token}\s"
    end

    def target_cluster_if_necessary
      # If we're not making a config call (a call to configure kubectl), we'll explicitly set the 
      # cluster name. We'll not set contexts as we're going to want to be able to play with
      # all our clusters at the same
      @is_config ? "\s" : "\s--cluster=#{@cluster.name}\s" 
    end

    def data
      @data ||= parse_data
    end

    def access_token
      network_driver.network_credentials[:access_token]
    end 

    def network_driver
      @cluster.network_driver
    end

    private

    def parse_data
      if as_json?   
        ## Parse JSON output and return it
        begin
          return JSON.parse(result.stdout)
        rescue TypeError, JSON::ParserError
          raise ::Bcome::Exception::Generic, "Kubectl parse failed"
        end
      else
        ### Simple text output, let's return it as is.
        return result 
      end
    end
  
    def result 
      #puts "#{full_command}\n"
      @result ||= ::Bcome::Command::Local.run(full_command)
    end

  end
end
