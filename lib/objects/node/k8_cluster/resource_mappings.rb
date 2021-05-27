module Bcome::Node::K8Cluster::ResourceMappings

  def crds
    @crds ||= {}
  end

  def resource_klasses
    {
      "Pod" => ::Bcome::Node::K8Cluster::Pod,
      "Ingress" => ::Bcome::Node::K8Cluster::Ingress,
      "Service" =>  ::Bcome::Node::K8Cluster::Service
    }
  end
  
  def crd_resource_klass
    ::Bcome::Node::K8Cluster::Crd
  end

  def focus_on
    ::Bcome::Node::K8Cluster::Pod  # Flex point for CRD namespace focus
  end 

  def focus_on?(resource_klass)
    resource_klass == focus_on
  end

  def add_resource(resource_klass, resource_type, data)
    resource = resource_klass.new(views: {identifier: data["metadata"]["name"], raw_data: data }, parent: self)
 
    resources << resource if focus_on?(resource_klass)
    
    if crds[resource_type]
      crds[resource_type] << resource
    else
      crds[resource_type] = [resource]
    end

    resource.set_child_nodes if respond_to?(:set_child_nodes)

    ::Bcome::Node::Factory.instance.bucket[resource.keyed_namespace] = resource
  end
end
