module Bcome::Node::K8Cluster::PathwayRender

  def routes(node = self)
    if node.is_a?(Bcome::Node::K8Cluster::Collection::Gcp)
      return # not currently supported at cluster level, namespace only
    else
      if (node != self) && (resource = resources.for_identifier(node))
        resource.send(:routes)
      else
        caller_stack = {}
        build_tree(:pathway_data, "routes", caller_stack)
      end
    end
    return
  end
  alias :pathways :routes 

  def pathway_data(*params)
    retrieve(["services", "pods", "ingresses"])
    map = {}

    return map if ingresses.nil?

    ingresses.each{|ingress|
      map.deep_merge!(ingress.pathway_data(params))
    }
    return map
  end
end
