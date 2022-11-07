module Bcome::Node::K8Cluster::PathwayRender

  def pathways(node = self)
    if (node != self) && (resource = resources.for_identifier(node))
      resource.send(:routes)
    else
      caller_stack = {}
      build_tree(:pathway_data, "routes", caller_stack)
    end
    return
  end

  def pathway_data(*params)
    if is_a?(Bcome::Node::K8Cluster::Collection::Gcp)
      merged_path_data = {}
      resources.active.each {|namespace|
        merged_path_data.deep_merge!(namespace.pathway_data)
      }
      return merged_path_data
    else
      retrieve(["services", "pods", "ingresses"])
      map = {}

      return map if ingresses.nil?

      ingresses.each{|ingress|
        map.deep_merge!(ingress.pathway_data(params))
      }
      return map
    end
  end
end
