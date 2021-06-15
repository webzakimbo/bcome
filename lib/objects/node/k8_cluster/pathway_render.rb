module Bcome::Node::K8Cluster::PathwayRender

  def tree(node = self)
    if (node != self) && (resource = resources.for_identifier(node))
      resource.send(:pathways)
    else
      build_tree(:pathway_data, "pathways")
    end
  end

  def pathway_data
    map = {}

    return map if ingresses.nil?

    ingresses.each{|ingress|
      map.deep_merge!(ingress.pathway_data)
    }
    return map
  end
end
