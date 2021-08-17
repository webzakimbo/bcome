module Bcome::Node::K8Cluster::Collection
  class Aws < Base

    def required_attributes
      [:cluster_name]
    end

    def cluster_id
      "#{cluster_name}" 
    end

  end
end