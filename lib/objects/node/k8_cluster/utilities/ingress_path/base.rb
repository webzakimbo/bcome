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

    def print(show_broken_path = false)
      return nil if broken_path?
      puts "#{scheme}://#{@rule.host}#{path} ~> #{path_print_service}"
    end

    def pathway_data
      return { "X".error => nil } if broken_path?

      if service.target.is_a?(::Bcome::Node::K8Cluster::Pod)
         service.target.pathway_data(scheme, service_port)
      else
        return {"#{scheme}://#{service.target.identifier}:#{service_port}" => nil  }
      end
    end

    def broken_path?
      service.nil? || service.target.nil? 
    end
  
    def scheme
      raise "Should be overidden"
    end

    def service
      @service ||= find_service
    end

    def service_port
      backend["servicePort"]
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
      @config["path"]
    end

    private

    def find_service
      ingress.parent.crds["Service"].select{|service|
        (service.name == service_name) && service.ports.collect{|port| port.port == service_port }.any?
      }.first
    end
  end 
end
