module Bcome::Node::K8Cluster::Utilities
  class Port

    def initialize(config)
      @config = config
    end  

    def name
      @config["name"]
    end

    def port
      @config["port"]
    end

    def protocol
      @config["protocol"]
    end

    def target_port
      @config["targetPort"]
    end
  end 
end
