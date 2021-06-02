module Bcome::Node::K8Cluster::Utilities::IngressPath
  class Base

    def initialize(rule, config)
      @config = config
      @rule = rule
    end  

    def ingress
      @rule.ingress
    end 

    def backend
      @config["backend"]
    end

    def service
      @service ||= find_service
    end

    def service_name
      backend["serviceName"]
    end

    def service_port
      backend["servicePort"]
    end

    def path_type
      backend["pathType"]
    end 

    def path
      backend["path"]
    end

    private

    def find_service
      ingress.parent.crds["Service"].select{|service|
        service.name == service_name  
      }.first
    end
  end 
end
