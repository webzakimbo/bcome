module Bcome::Node::K8Cluster::ResourceMappings

  def crds
    @crds ||= get_crds
  end

  def switch(crd_key)
    raise "You may only utilize switch with singular resources" if "#{crd_key}".split.size > 1 || crd_key =~ /,/

    switch_focus = true
    items = get_kubectl_resource(crd_key, switch_focus)
    other = ::Bcome::Orchestrator.instance.get(keyed_namespace)
    ::Bcome::Workspace.instance.set(current_context: other, context: other)
  end
  alias :focus :switch
 
  def get_crds
    collate_child_crds? ? collate_child_crds : {}
  end

  def collate_child_crds?
    respond_to?(:is_subdivided) && is_subdivided
  end

  def collate_child_crds
    new_collection = {}
    child_crds = resources.collect(&:crds)
    child_crds.each{|collection| collection.keys.each{|key| new_collection[key] ? (new_collection[key] << collection[key]) : (new_collection[key] = collection[key].dup) ; new_collection[key].flatten! } }
    return new_collection
  end

  def resource_klasses
    {
      "Pod" => ::Bcome::Node::K8Cluster::Pod,
      "Ingress" => ::Bcome::Node::K8Cluster::Ingress,
      "Service" =>  ::Bcome::Node::K8Cluster::Service,
      "CronJob" => ::Bcome::Node::K8Cluster::CronJob,
      "Crd" => ::Bcome::Node::K8Cluster::Crd,
      "Deployment" => ::Bcome::Node::K8Cluster::Deployment
    }
  end
  
  def crd_resource_klass
    ::Bcome::Node::K8Cluster::Crd
  end

  def focus_breadcrumb
    resource_key = resource_klasses.select{|key,value| value == ::Bcome::Workspace.instance.kubernetes_focus_on }.first[0]
    resource_key.downcase.pluralize
  end

  def focus_on?(resource_klass)
    resource_klass == ::Bcome::Workspace.instance.kubernetes_focus_on
  end

  def add_resource(resource_klass, resource_type, data)
    resource = resource_klass.new(views: {identifier: data["metadata"]["name"], raw_data: data }, parent: self)
    resources << resource if focus_on?(resource_klass) ## TODO set focus_on before we start adding resources
    
    if crds[resource_type]
      crds[resource_type] << resource
    else
      crds[resource_type] = [resource]
    end

    resource.set_child_nodes if resource.respond_to?(:set_child_nodes)
    ::Bcome::Node::Factory.instance.bucket[resource.keyed_namespace] = resource
    return resource
  end
end
