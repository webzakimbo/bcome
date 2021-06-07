module Bcome::Node::K8Cluster::Utilities
  class IngressRule

    # Ref: https://kubernetes.io/docs/concepts/services-networking/ingress/

    attr_reader :ingress, :config

    def initialize(ingress, config)
      @config = config
      @ingress = ingress
    end  

    def path_print(show_broken = false)
      paths.each {|path| 
        path.print(show_broken)
      }
      return
    end

    # Optional host, if not provided, then the rule applies to all inbound http traffic through the IP address specified.
    def host
      @config["host"]
    end

    def paths
      (http_paths + https_paths).flatten
    end

    def http_paths
      @http_paths ||= get_paths("http")
    end

    def https_paths
      @https_paths ||= get_paths("https")
    end  

    def services
      paths.collect(&:service)
    end
 
    private

    def get_paths(key)
      return [] unless @config[key] && @config[key]["paths"]
      
      @config[key]["paths"].collect{|path_data|
        path_klasses[key].new(self, path_data)
      }
    end

    def path_klasses
      {
        "http" => ::Bcome::Node::K8Cluster::Utilities::IngressPath::Http,
        "https" => ::Bcome::Node::K8Cluster::Utilities::IngressPath::Https
      }
    end
  end 
end
