module Bcome::K8Cluster::Hierarchy
  class Loader

    attr_reader :views

    def initialize(k8_namespace)
      @k8_namespace = k8_namespace
      @hierarchy_schema = ::Bcome::Node::K8Cluster::HierarchySchema.instance.schema
      @views = []
      construct_config_items
    end

    def config_for_name(name)
      @views.select{|view| view.name == name.to_s }.first
    end
    alias :for_name :config_for_name 

    def console_view
      @console_view ||= set_console_view
    end

    def available_views
      @views.collect(&:name)
    end

    protected

    def set_console_view
      view = @hierarchy_schema["default_view"] ? load_default_view : views.first
      raise ::Bcome::Exception::Generic, "\nNo configured hierarchy views found in K8 hierarchy configuration" unless view
      return view
    end

    def load_default_view
      default_view_name = @hierarchy_schema["default_view"]
      view = views.detect{|view| view.name == default_view_name }
      raise ::Bcome::Exception::Generic, "\nCould not find default K8 hierarchy view '#{default_view_name}'" unless view
      return view
    end

    def construct_config_items
      raise ::Bcome::Exception::Generic, "\nMissing key 'views' in K8 hierarchy configuration" unless @hierarchy_schema.has_key?("views")
      view_configs = @hierarchy_schema["views"]

      view_configs.each{|raw_config|
        config = Bcome::K8Cluster::Hierarchy::View.new(raw_config, @k8_namespace)
        add_config(config)
      }
    end

    def add_config(config)
      raise ::Bcome::Exception::Generic, "Error: Duplicate k8 hierarchy config name '#{config.name}' at '#{FILE_PATH}'" if config_for_name(config.name)
      @views << config
    end
  end
end
