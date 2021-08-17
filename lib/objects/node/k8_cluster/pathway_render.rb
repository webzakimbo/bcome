module Bcome::Node::K8Cluster::PathwayRender

  def pathways(node = self)
    if (node != self) && (resource = resources.for_identifier(node))
      resource.send(:pathways)
    else
      build_tree(:pathway_data, "pathways")
    end
    return
  end

  def pathway_data
    get_kubectl_resource(["services", "pods", "ingresses"])
    map = {}

    return map if ingresses.nil?

    ingresses.each{|ingress|
      map.deep_merge!(ingress.pathway_data)
    }
    return map
  end
end
