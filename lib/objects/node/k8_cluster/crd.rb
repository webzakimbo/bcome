# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Crd < Bcome::Node::K8Cluster::Child
    # Abstract: essentially a catch-all for a resource in a namespace that we haven't otherwise 
    # modelled.
  end
end
