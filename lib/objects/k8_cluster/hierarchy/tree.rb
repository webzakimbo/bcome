module Bcome::K8Cluster::Hierarchy
  class Tree

    attr_reader :resources, :hierarchy, :node, :view, :config

    def initialize(config, node, view)
      @config = config
      @resource_names = []
      @node = node
      @hierarchy = construct_hierarchy
      @view = view
      validate_top_level_node
    end

    def nodes
      @nodes ||= duplicate_node.resources
    end

    def resources_of_type(resource_key)
      resources.select{|resource| resource.type == resource_key }
    end  

    def add_resource(resource_name)
      # The resources we'll retrieve in one hit to cut down on API calls
      # User may define as Foo or foo or foos or Foos
      @resource_names << resource_name.downcase.singularize 
    end

    def focus
      @node.switch_hierarchy(@view)
    end

    def render
      duplicate_node.tree
    end

    def duplicate_node
      @duplicate_node ||= set_duplicate_node
    end 

    # The pool of defined resources in this namespace, that may make part of any new workspace generated from the hierarchy schema
    # We front-load all candidate resources to reduce API calls to one
    def selection_pool
      raise ::Bcome::Exception::Generic, "Error in K8 hierarchy config '#{@config}' - no top-level resources defined." unless @resource_names.any?

      # Outside of hierarchy views we may load in child nodes automatically where it makes sense. We explicitly override that here, as we are only concerned
      # with that which our hiearchy defines (e.g. do not auto-load containers as children of pods, because it is the hierarchy rules that define whether there are
      # children, and what they are.
      @set_children = false
      @selection_pool ||= other.retrieve(@resource_names, @set_children)
    end

    def top_level_config
      config.first
    end

    def do_set_decorators(resource, decorators)
      json_config = resource.views[:raw_data].to_json
      attributes = {}

      decorators.each do |decorator|
        path_data = ::JsonPath.new(decorator[:json_path]).on(json_config)
        next unless path_data
        value = path_data.first
        resource.define_method_name_with_value(decorator[:name], value)
        attributes[decorator[:name].to_s] = decorator[:name].to_sym
      end
      resource.set_additional_list_attributes(attributes)
    end
    
    private

    def set_duplicate_node 
      top_level_resource_type = @resource_names.first
      top_level_nodes = selection_pool.select{|resource| resource.type == top_level_resource_type }

      top_level_nodes.each do |child_node|
        do_set_decorators(child_node, top_level_config[:decorators]) if top_level_config[:decorators]
        @hierarchy.set_resources_for(child_node)
      end

      other.resources.nodes = top_level_nodes
      return other
    end  

    # Our hierarchies are loaded into a duplicated node to which we may switch our workspace focus, render them as a tree view etc
    def other
      @other ||= create_other
    end

    def create_other
      other = @node.dup
      other.unset_crds
      other.resources = ::Bcome::Node::Resources::Base.new 
      return other
    end

    def construct_hierarchy
      next_config = @config.first
      subsequent_config = @config[1..@config.size]
      return ::Bcome::K8Cluster::Hierarchy::Element::Base.construct(data: next_config, subsequent: subsequent_config,  tree: self, parent: nil)
    end

    def validate_top_level_node
      # Top level nodes must not be abstract
      top_level = @config.first
      raise ::Bcome::Exception::Generic, "\nError in K8 Hierarchy config #{@config}. \n\nFirst K8 node must be a named and not an abstract resource." if top_level.has_key?(:abstract)
    end

  end
end
