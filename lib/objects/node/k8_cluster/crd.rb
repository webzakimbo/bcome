# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Crd < Bcome::Node::K8Cluster::Child
    # Abstract: essentially a catch-all for a resource in a namespace that we haven't otherwise 
    # modelled.

    def type=(declared)
      @type = "(abstract) #{declared}"
    end

    def type
      @type ||= raw_config_data["kind"].downcase
    end

    def list_attributes
      @attributes || super
    end
  end
end
