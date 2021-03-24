module Bcome::Node::K8Cluster
  class Base < Bcome::Node::Base

    include ::Bcome::InteractiveKubectl

    def kubectl_context
      "#{parent.kubectl_context}.#{hyphenated_identifier}"
    end

    def get(crd_key)
      data = run_kc("get #{crd_key}")
      raise ::Bcome::Exception::Generic, "No items returned from call to 'get #{crd_key}'" if !data.is_a?(Hash) && data.has_key?(:items)
      return data["items"]
    end

  end
end
