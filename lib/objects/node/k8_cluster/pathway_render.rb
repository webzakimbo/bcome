module Bcome::Node::K8Cluster::PathwayRender

  def paths(node = self)
   # if node.is_a?(Bcome::Node::K8Cluster::Collection::Gcp)
   #   return # not currently supported at cluster level, namespace only
   # else
      if (node != self) && (resource = resources.for_identifier(node))
        resource.send(:routes)
      else
        caller_stack = {}
        build_tree(:pathway_data, "routes", caller_stack)
      end
    #end
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
