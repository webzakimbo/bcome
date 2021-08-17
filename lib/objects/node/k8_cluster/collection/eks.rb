module Bcome::Node::K8Cluster::Collection
  class Eks < Base

    def required_attributes
      [:cluster_name]
    end

    def cluster_id
      "#{cluster_name}" 
    end

    def account_id
      cluster[:account_id]
    end

    def do_get_credentials
      @k8_cluster = ::Bcome::Driver::Kubernetes::Eks.new(self)
    end

  end
end