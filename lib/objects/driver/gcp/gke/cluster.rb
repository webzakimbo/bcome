module ::Bcome::Driver::Gcp::Gke
  class Cluster

    def initialize(node)
      raise "Invalid collection class for #{self.class}" unless node.is_a?(::Bcome::Node::Collection::Kube)
      @node = node
    end  

    def config
      @config ||= get_config
    end  

    private

    def get_config
      json_config = ::Bcome::Driver::Gcp::ApiClient::Request.do(URI(get_config_url), @node)
      binding.pry
    end

    def get_config_url
      "https://container.googleapis.com/v1/projects/#{@node.project}/locations/#{@node.region}/clusters/#{@node.cluster_name}?alt=json"
    end  

    def network_driver
      @node.network_driver
    end

  end
end
