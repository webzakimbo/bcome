module Bcome::Node::K8Cluster::ResourceMappings

  def crds
    @crds ||= get_crds
  end

  def unset_crds
    @crds = nil
  end  

  # Where user focuses on one specific resource, by type e.g. focus secrets
  def focus(crd_key)
    raise "You may only utilize switch with singular resources" if "#{crd_key}".split.size > 1 || crd_key =~ /,/

    # Get the resource
    items = get_kubectl_resource(crd_key)

    if items.any?
      switch_focus(items)
    else
      puts "No resources of type '#{crd_key}' found".informational
    end
  end

  def refresh_cache!(items)
    kinds = items.collect{|item| item["kind"]}.uniq
    kinds.each {|kind|
      # refresh crds cache
      crds[kind] = []
      resources.wipe!
    }
  end

  #####################################
  ## Change focus to a new items set ##
  #####################################
  def switch_hierarchy(hierarchy_view)
    puts "\nSwitching hierarchy: ".informational + "\s#{hierarchy_view.name}\n\n"
    switch_to_node = hierarchy_view.hierarchy_node
    @focus_on = switch_to_node.resources.first.class
    switch_to_node.reset_registry
    ::Bcome::Workspace.instance.set(current_context: switch_to_node, context: switch_to_node)
  end

  ##########################################################################################################################
  ## Change focus where user chooses to switch to a specific resource type using "focus resource_name e.g. focus secrets"  #
  ##########################################################################################################################
  def switch_focus(items)
    key = items.first["kind"]
    switch_should_focus_on = resource_klasses[key] ? resource_klasses[key] : crd_resource_klass

    # Create new workspace
    other = self.dup
    other.focus_on = switch_should_focus_on
    other.set_switched_resources(items)

    ::Bcome::Workspace.instance.set(current_context: other, context: other)
  end
 
  def set_switched_resources(items)
    # Used when we switch focus - we instantiate a new instance of our current workspace, but
    # we set the newly retrieved items as its resources.
    @resources = ::Bcome::Node::Resources::Base.new
    refresh_cache!(items)
    do_set_switched_resources(items)
  end

  def do_set_switched_resources(raw_resources)
    return [] if raw_resources.empty?

    raw_resources.each do |resource|
      resource_type = resource["kind"]
      resource_klass = resource_klasses[resource_type]
      resource_klass = crd_resource_klass unless resource_klass
      add_resource(resource_klass, resource_type, resource)
    end
  end

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
      "Namespace" => ::Bcome::Node::K8Cluster::Namespace,
      "Pod" => ::Bcome::Node::K8Cluster::Pod,
      "Ingress" => ::Bcome::Node::K8Cluster::Ingress,
      "Service" =>  ::Bcome::Node::K8Cluster::Service,
      "CronJob" => ::Bcome::Node::K8Cluster::CronJob,
      "Crd" => ::Bcome::Node::K8Cluster::Crd,
      "Deployment" => ::Bcome::Node::K8Cluster::Deployment,
      "VirtualService" => ::Bcome::Node::K8Cluster::VirtualService,
      "Secret" => ::Bcome::Node::K8Cluster::Secret
    }
  end
  
  def crd_resource_klass
    ::Bcome::Node::K8Cluster::Crd
  end

  def focus_breadcrumb
    return nil unless resources.any?
    return resources.first.type.pluralize
  end

  def focus_on?(resource_klass)
    resource_klass == focus_on
  end

  def focus_on
    @focus_on ||= ::Bcome::Workspace.instance.kubernetes_focus_on
  end

  def focus_on=(to_focus_on)
    @focus_on = to_focus_on
    ::Bcome::Workspace.instance.set_kubernetes_focus(to_focus_on)
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
