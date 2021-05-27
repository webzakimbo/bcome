# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Service < Bcome::Node::K8Cluster::Child

    include ::Bcome::Node::K8Cluster::Selector

    def cluster_ip
      spec["clusterIP"]
    end  

    def ports
      @ports ||= instantiate_ports
    end

    def pod
      @pod ||= selected
    end

    def selector_kind
      "Pod"
    end

    private

    def instantiate_ports
      spec["ports"].collect{|port_spec|
        ::Bcome::Node::K8Cluster::Utilities::Port.new(port_spec)
      }
    end

  end
end
