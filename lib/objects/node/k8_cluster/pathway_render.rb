module Bcome::Node::K8Cluster::PathwayRender

  def pathways(node = self)
    if node.is_a?(Bcome::Node::K8Cluster::Collection::Gcp)
      return # not currently supported at cluster level, namespace only
    else
      if (node != self) && (resource = resources.for_identifier(node))
        resource.send(:pathways)
      else
        caller_stack = {}
        build_tree(:pathway_data, "pathways", caller_stack)
      end
    end
    return
  end

  def pathway_data(*params)
    get(["services", "pods", "ingresses"])
    map = {}

    return map if ingresses.nil?

    ingresses.each{|ingress|
      map.deep_merge!(ingress.pathway_data(params))
    }
    return map
  end
end
