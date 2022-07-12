module ::Bcome::Node::K8Cluster::NamespaceHierarchy
  def hierarchy
    ::Bcome::K8Cluster::Hierarchy::Loader.new(self)
  end

  def hierarchy_views
    hierarchy.views
  end

  def available_hierarchies
    hierarchy.available_views
  end
 
  def pretty_available_hierarchies
    available_hierarchies.join(", ")
  end  

  ## Switch the current hierarchy to hierarchy 'name'
  def vfocus(name)
    vscope(name, :focus)
  end

  ## Render 'name' hierarchy
  def vrender(name)
    vscope(name, :render)
  end

  def vscope(name, method)
    view = hierarchy.for_name(name)
    if view
      ::Bcome::System::Local.instance.k8_view = view
      view.send(method)
    else
      puts "Could not find hierarchy view named '#{name}'. Available hierarchies: #{pretty_available_hierarchies}".warning
    end

  end
end
