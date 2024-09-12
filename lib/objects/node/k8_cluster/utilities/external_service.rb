module Bcome::Node::K8Cluster::Utilities
  class ExternalService

    def initialize(host)
      @host = host
    end  

    def identifier
      @host
    end
  end 
end
