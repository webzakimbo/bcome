module Bcome::Node::K8Cluster::PathwayRender

  def pathways
    build_tree(:pathway_data, "pathways")
  end

  def pathway_data
    map = {}
    ingresses.each{|ingress|
      map.deep_merge!(ingress.pathway_data)
    }
    return map
  end
end
