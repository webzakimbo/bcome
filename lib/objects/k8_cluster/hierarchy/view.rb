module Bcome::K8Cluster::Hierarchy
  class View

    attr_reader :node

    def initialize(config, node)
      @config = config.deep_symbolize_keys!
      @node = node
      validate
    end
 
    def tree
      @tree ||= do_construct_tree
    end
 
    def name
      @config[:name]
    end

    def focus
      tree.focus
    end

    def render
      tree.render
    end

    def hierarchy_node
      tree.duplicate_node
    end 

    private

    def do_construct_tree
      ::Bcome::K8Cluster::Hierarchy::Tree.new(@config[:tree], @node, self)
    end

    def validate
      raise ::Bcome::Exception::Generic, "Error: Missing name for k8 hierarchy config #{@config.inspect}" unless name
      raise ::Bcome::Exception::Generic, "Error: Invalid name '#{name}' in k8 hierarchy config. Name must match /^[a-z0-9]$/" unless name =~ /^[a-z]+$/
    end
  end
end
