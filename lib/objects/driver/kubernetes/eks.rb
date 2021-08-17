module ::Bcome::Driver::Kubernetes
  class Eks < Cluster

    def register_cluster
      get_configuration
      get_token
      register_context
    end

    def get_configuration
      cmd = "eks update-kubeconfig --name #{cluster_name} --kubeconfig #{path_to_global_kubectl_config} --region #{cluster_region}"
      aws_run(cmd)
    end
   
    def get_token
      cmd = "eks get-token --cluster-name newron-prod"     
      runner = aws_run(cmd)

      begin
        auth_data = JSON.parse(runner.stdout)
      rescue RuntimeError => e
        raise ::Bcome::Exception::Generic, "Error retrieving authentication data for cluster #{cluster_name}. \n#{e.class}\n#{e.message}"
      end

      token = (auth_data["status"] && auth_data["status"]["token"]) ? auth_data["status"]["token"] : nil

      raise ::Bcome::Exception::Generic, "Could not retrieve authorisation token from cluster #{cluster_name}'s API response: #{auth_data}" unless token
      network_credentials[:access_token] = token
    end  

    def register_context
      run_kubectl_config("config set-context #{cluster_name} --cluster=#{cluster_name}")
    end

    def aws_run(cmd)
      ::Bcome::Command::Aws.run(cmd, @node.network_driver)
    end

    def network_credentials
      @node.network_driver.network_credentials 
    end

    def expected_collection_class
      ::Bcome::Node::K8Cluster::Collection::Eks
    end

    def aws_cli_command
      return "eks update-kubeconfig --name #{cluster_name} --kubeconfig #{path_to_global_kubectl_config} --region #{cluster_region}"
    end
    
    def cluster_name
      @node.cluster_name
    end

    def account_id
      @node.account_id
    end  

    def name
      "arn:aws:eks:#{cluster_region}:#{@node.account_id}:cluster/#{@node.cluster_name}"
    end

    def path_to_global_kubectl_config
      ::Bcome::K8Cluster::CommandRunner::BCOME_K8_CONFIG_FILE_PATH
    end

    def cluster_region
      @node.network_driver.provisioning_region
    end
  end
end
