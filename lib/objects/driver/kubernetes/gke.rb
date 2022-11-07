module ::Bcome::Driver::Kubernetes
  class Gke < Cluster

    def config
      @config ||= get_config
    end

    def status
      config["status"]
    end

    def endpoint
      config["endpoint"]
    end

    def registered?
      check_context = run_kubectl_config("config get-contexts #{name}")
      return check_context.is_success?
    end

    def cluster_certificate
      config["masterAuth"]["clusterCaCertificate"]
    end

    def username
      "#{NAME_PREFIX}_#{@node.project}_#{@node.cluster_name}"
    end

    def name
      "#{@node.cluster_name}-#{@node.region}_#{@node.project}"
    end

    def expected_collection_class
      ::Bcome::Node::K8Cluster::Collection::Gcp
    end 

    def register_cluster
      register_cluster_in_config
      register_cluster_certificate_in_config
      set_cluster_access_token
      register_cluster_context
    end

    def register_cluster_in_config
      run_kubectl_config("config set-cluster #{name} --server=#{server}")
    end

    def register_cluster_certificate_in_config
      run_kubectl_config("config set clusters.#{name}.certificate-authority-data #{cluster_certificate}")
    end

    def set_cluster_access_token
      run_kubectl_config("config set-credentials #{username} --token=#{access_token}")
    end

    def access_token
      @node.network_driver.network_credentials[:access_token]
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
