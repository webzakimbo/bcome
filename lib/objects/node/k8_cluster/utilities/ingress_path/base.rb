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

      targets = service.targets.uniq
      
      map = {}
      targets.each do |target|

        if target.is_a?(::Bcome::Node::K8Cluster::Pod)
          next if target.is_job?
          map.merge!(target.pathway_data(scheme, service_port))
        else
          target.merge!({"#{scheme}://#{target.identifier}:#{service_port}" => nil })
        end
      end

      return map
    end

    def broken_path?
      service.nil? || service.targets.empty? 
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
      services.select{|service|
        (service.name == service_name) && service.ports.collect{|port| port.port == service_port }.any?
      }.first
    end

    def services
      srvs = ingress.parent.crds["Service"]
      return srvs.nil? ? [] : srvs
    end
  end 
end
