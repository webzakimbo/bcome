module Bcome::K8Cluster
  class CommandRunner

    KUBECTL_BINARY = "kubectl".freeze
    BCOME_K8_CONFIG_FILE_PATH = ".kubectl/conf".freeze

    attr_reader :local_command
 
    def initialize(cluster, command_suffix, output, call_type)
      @command_suffix = command_suffix
      @output = output
      @cluster = cluster

      @is_config = call_type == :config_call
      @is_command = call_type == :command_call 
      @cluster_call = @is_command || call_type == :cluster_call   
    end

    def as_json?
      @output == :as_json
    end

    def full_command
      cmd = "#{KUBECTL_BINARY}#{add_access_token_if_necessary}--kubeconfig=#{BCOME_K8_CONFIG_FILE_PATH}#{target_cluster_if_necessary}#{@command_suffix}#{ as_json? ? " -o json" : ""}"

      if ::Bcome::PipedInput.instance.pipe?
        cmd = "#{cmd}#{::Bcome::PipedInput.instance.command_suffix}" 
        ::Bcome::PipedInput.instance.unset!
      end

      return cmd
    end

    def add_access_token_if_necessary
      # If we're not making a config call (a call to configure kubectl
      !@cluster_call ? "\s" : "\s--token=#{access_token}\s"
    end

    def target_cluster_if_necessary
      # If we're not making a config call (a call to configure kubectl), we'll explicitly set the 
      # cluster name. We'll not set contexts as we're going to want to be able to play with
      # all our clusters at the same
      !@cluster_call ? "\s" : "\s--cluster=#{@cluster.name}\s" 
    end

    def run_local
      @local_command ||= ::Bcome::Command::Local.run(full_command)
    end

    def run_hand_off
      to_run = full_command

      puts "\n(#{"local".bc_yellow}) > #{to_run}\n\n" unless ::Bcome::Orchestrator.instance.command_output_silenced?
      system(to_run)
      puts ''
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
          raise ::Bcome::Exception::Generic, result.stderr if result.stderr
          raise ::Bcome::Exception::Generic, "Kubectl parse failed"
        end
      else
        ### Simple text output, let's return it as is.
        return result 
      end
    end
  
    def result 
      #print_command_and_obfuscate_token(full_command)
      @result ||= ::Bcome::Command::Local.run(full_command)
    end
 
    def print_command_and_obfuscate_token(command)
      command.gsub!(/--token=([0-9A-Za-z\-_.]+)/,"--token=*****\s")
      command.gsub!(/certificate-authority-data\s([0-9A-Za-z])+/, "certificate-authority-data\s*****")
      puts "#{command}".bc_grey 
    end
  end
end
