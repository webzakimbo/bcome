# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Service < Bcome::Node::K8Cluster::Child

    include ::Bcome::Node::K8Cluster::Selector
    include ::Bcome::Node::KubeTunnelHelper

    def shorthand
      "svc"
    end

    def cluster_ip
      spec["clusterIP"]
    end  

    def ports
      @ports ||= instantiate_ports
    end

    def targets
      @targets ||= get_targets
    end

    def selector_kind
      "Pod"
    end

    def ingresses
      @ingress ||= parent.crds["Ingress"].select{|i| 
        i.for_service?(self) 
      }
    end

    def external_service
      @external_service ||= ::Bcome::Node::K8Cluster::Utilities::ExternalService.new(spec["externalName"])
    end

    private

    def get_targets
      return [external_service] if service_type == "ExternalName"
      return selected
    end

    def service_type
      spec["type"]
    end  

    def instantiate_ports
      return [] unless spec["ports"]
      spec["ports"].collect{|port_spec|
        ::Bcome::Node::K8Cluster::Utilities::Port.new(port_spec)
      }
    end
  end
end
