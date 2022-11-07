module Bcome::K8Cluster::Hierarchy::Element
  class Base

    attr_reader :child, :parent, :data, :tree, :nodes

    class << self
      def construct(config)
        klass = config[:data][:abstract] ? Abstract : Resource
        return klass.new(config)
      end
    end

    def initialize(config)
      @data = config[:data]
      @subsequent = config[:subsequent]
      @tree = config[:tree]
      @parent = config[:parent]

      # Our tree functions as a wrapper for all elements in the hierarchy and will load all resources
      @tree.add_resource @data[:resource] if !is_abstract?

      @nodes = []
      set_child if has_child?
    end

    def do_set_decorators(resource, decorators)
      @tree.do_set_decorators(resource, decorators)
    end

    def child_specification_for(node)
      return unless child
      child.specification_for(node)
    end

    def set_resources_for(node)
      spec = child_specification_for(node)
      spec.set_resources if spec
    end  

    def has_child?
      !@subsequent.empty?
    end

    def specification_for(node)
      ::Bcome::K8Cluster::Hierarchy::Specification::Base.construct(data, node, self)
    end

    private

    def set_child
      @child ||= do_create_child
    end
   
    def do_create_child
      next_config = @subsequent.first
      subsequent = @subsequent[1..@subsequent.size]
      return ::Bcome::K8Cluster::Hierarchy::Element::Base.construct(data: next_config, subsequent: subsequent, tree: @tree, parent: self)
    end
  end
end
