module Bcome::K8Cluster::Hierarchy::Specification
  class JsonPath < Base

    def do_set_resources
      retrieve.each_with_index do |raw_data,index|

        if raw_data.is_a?(Hash) && merges[index]
          raw_data.merge!(merges[index])
        end

        resource_config = {
          identifier: raw_data["name"] ? raw_data["name"] : "#{index}-#{config[:abstract]}",
          raw_data: raw_data
        }

        resource = resource_klass.new(views: resource_config, parent: parent)
        resource.type = config[:abstract] if is_custom_resource?

        add_resource(resource)
      end
    end

    def is_custom_resource?
      !config[:retrieval][:klass] 
    end

    def resource_klass
      is_custom_resource? ? ::Bcome::Node::K8Cluster::Crd : config[:retrieval][:klass].constantize
    end

    def json
      parent.raw_data.to_json
    end

    def retrieve
      @retrieved ||= paths.collect {|path|
        ::JsonPath.new(path).on(json).flatten
      }.flatten.compact
    end

    def merges
      return [] unless has_merge_paths?

      @merges ||= merge_paths.collect {|path|
        ::JsonPath.new(path).on(json).flatten
      }.flatten.compact
    end

    def has_merge_paths?
      config[:retrieval][:mergePaths]
    end

    def paths
      config[:retrieval][:paths]
    end

    def merge_paths
      config[:retrieval][:mergePaths]
    end

    def validate
      raise ::Bcome::Exception::Generic, "Invalid k8 cluster hierarchy config #{config}" unless is_valid_specification?
    end

    def is_valid_specification?
      config[:retrieval] && config[:retrieval][:paths] && config[:abstract]
    end
  end
end

