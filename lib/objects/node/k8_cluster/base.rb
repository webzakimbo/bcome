module Bcome::Node::K8Cluster
  class Base < Bcome::Node::Base

    include ::Bcome::InteractiveKubectl

    def kubectl_context
      "#{parent.kubectl_context}.#{hyphenated_identifier}"
    end

    def get(crd_key)
      data = run_kc("get #{crd_key}")
      raise ::Bcome::Exception::Generic, "No items returned from call to 'get #{crd_key}'" if !data.is_a?(Hash) && data.has_key?(:items)
      items = data["items"]

      refresh_cache!(items)

      do_set_resources(items)
      return items
    end

    def refresh_cache!(items)
      kinds = items.collect{|item| item["kind"]}.uniq
      kinds.each {|kind| 
        # refresh crds cache
        crds[kind] = []

        # then blat resources if we've a focus_on on these (tree view & bcome nav refresh)
        resource_klass = resource_klasses[kind]
        resources.wipe! if focus_on?(resource_klass)
      }
    end

    def spec
      raw_data["spec"]
    end

    def name
      raw_data["metadata"]["name"]
    end

  end
end
