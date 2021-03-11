module Bcome::Node::K8Cluster
  class Base < Bcome::Node::Base

    include ::Bcome::InteractiveKubectl

    def interactive
      kubectl
    end

    def kubectl_context
      "#{parent.kubectl_context}.#{hyphenated_identifier}"
    end

  end
end
