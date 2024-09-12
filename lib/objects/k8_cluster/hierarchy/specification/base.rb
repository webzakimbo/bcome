module Bcome::K8Cluster::Hierarchy::Specification
  class Base

    class << self
      def construct(config, parent, element)
        raise ::Bcome::Exception::Generic, "\nError: K8 Hierachy item #{config} is missing retrieval type. All child resources must specify a retrieval method." unless config[:retrieval]

        raise ::Bcome::Exception::Generic, "\nK8 hierarchy config '#{config}' is missing its retrieval type." unless config[:retrieval][:type]

        klass = get_klass(config[:retrieval][:type])
        return klass.new(config, parent, element)
      end

      def get_klass(retrieval_type)
        case retrieval_type
        when "json_path"
          ::Bcome::K8Cluster::Hierarchy::Specification::JsonPath
        when "by_reference"
          ::Bcome::K8Cluster::Hierarchy::Specification::ByReference
        when "by_selector"
          ::Bcome::K8Cluster::Hierarchy::Specification::BySelector
        else
          raise ::Bcome::Exception::Generic, "Invalid K8 Hierarchy retrieval type '#{retrieval_type}'"
        end
      end
    end

    attr_reader :parent, :config

    def initialize(config, parent, element)
      @config = config
      @parent = parent
      @element = element
      validate
    end

    def has_decorators?
      @config[:decorators] && @config[:decorators].is_a?(Array)
    end

    def decorators
      @config[:decorators]
    end 

    def add_resource(resource)
      # Decorate our resource if configured
      @element.do_set_decorators(resource, decorators) if has_decorators?     

      # Add to parent
      resource.parent = parent
      parent.resources << resource
      ::Bcome::Node::Factory.instance.bucket[resource.keyed_namespace] = resource
    end

    def set_resources
      do_set_resources

      @parent.resources.pmap do |node|
        next unless @element.child
        spec = @element.child.specification_for(node)
        spec.set_resources if spec
      end 
    end    

    def do_set_resources
      raise "Should be overidden"
    end

    def validate
      raise "Should be overidden"
    end 
  end
end
