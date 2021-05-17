module ::Bcome::Driver::Gcp::Gke::ClusterAttributes

    NAME_PREFIX="bcome".freeze

    def cluster_certificate
      config["masterAuth"]["clusterCaCertificate"]
    end

    def server
      "https://#{endpoint}"
    end

    def username
      "#{NAME_PREFIX}_#{@node.project}_#{@node.cluster_name}"
    end

    def name
      "#{@node.cluster_name}-#{@node.region}_#{@node.project}"
    end

    def remote_name
      @node.cluster_name
    end

    def running?
      status == "RUNNING"
    end

    def status
      config["status"]
    end

    def endpoint
      config["endpoint"]
    end

end
