module Bcome::K8Cluster::Hierarchy::Element
  class Resource < Base

    def is_abstract?
      false
    end
 
    def resource_key
      @data[:resource]
    end
  end
end
