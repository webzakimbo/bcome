module Bcome::Node::K8Cluster
  class Base < Bcome::Node::Base

    include ::Bcome::InteractiveKubectl

    def kubectl_context
      "#{parent.kubectl_context}.#{hyphenated_identifier}"
    end

    def get_kubectl_resource(crd_key, switch_focus = false)

      ## TODO - run the contextualised version of this for subselects (involves a re-filter)
      data = run_kc("get #{crd_key}") 

      raise ::Bcome::Exception::Generic, "No items returned from call to 'get #{crd_key}'" if !data.is_a?(Hash) && data.has_key?(:items)
      items = data["items"]

      if switch_focus
        key = items.first["kind"]
        set_focus_on = resource_klasses[key] ? resource_klasses[key] : crd_resource_klass
        ::Bcome::Workspace.instance.set_kubernetes_focus(set_focus_on)
      end

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
