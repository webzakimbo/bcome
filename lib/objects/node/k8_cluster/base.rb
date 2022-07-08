module Bcome::Node::K8Cluster
  class Base < Bcome::Node::Base

    include ::Bcome::InteractiveKubectl
    include ::Bcome::Node::K8Cluster::Selector
    include ::Bcome::Node::K8Cluster::Retrieve

    def is_describable?
      true
    end

    def reauthorize
      k8_cluster.reauthorize!
      return
    end

    def state
      views[:raw_data]["status"] ? views[:raw_data]["status"]["phase"] : nil
    end

    def enabled_menu_items
      (super + %i[reauthorize])
    end

    def menu_items
      base_items = super.dup

      base_items[:reauthorize] = {
        description: "Reauthorize with the cluster API",
        group: :kubernetes
      }

      base_items
    end

    def kubectl_context
      "#{parent.kubectl_context}.#{hyphenated_identifier}"
    end

    def get_kubectl_resource(crd_keys)
      resource_names = crd_keys.is_a?(Array) ? crd_keys.join(",") : crd_keys

      ## TODO - run the contextualised version of this for subselects (involves a re-filter)
      data = run_kc("get #{resource_names}") 

      raise ::Bcome::Exception::Generic, "No items returned from call to 'get #{crd_key}'" if !data.is_a?(Hash) && data.has_key?(:items)
      items = data["items"]

      return items
    end

    def refresh_cache!(items)
      kinds = items.collect{|item| item["kind"]}.uniq
      kinds.each {|kind| 
        # refresh crds cache
        crds[kind] = []
        resources.wipe!
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
