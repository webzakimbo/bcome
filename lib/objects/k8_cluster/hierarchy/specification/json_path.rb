module Bcome::K8Cluster::Hierarchy::Specification
  class JsonPath < Base

    def do_set_resources
      retrieve.each_with_index do |raw_data,index|

        # There are two different types of merges
        # (1) "mergePaths" Merge in from an array reference on the parent, e.g. merge in containerStatus[1] to container[1] -
        if raw_data.is_a?(Hash) && merges[index]
          raw_data.merge!(merges[index])
        end

        # (2) "cherryPick" Cherry-pick something from the parent and add it onto the abstract resource, e.g. the selector hash onto
        # a port resource generated from a service
        raw_data.merge!(cherry_picks) 

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
  
    def cherry_picks
      return {} unless has_cherry_picks?
      return @cherry_picks ||= get_cherry_picks
    end 

    def get_cherry_picks
      to_copy = {}
      config[:retrieval][:cherryPick].each do |cherry_pick|
        raw = ::JsonPath.new(cherry_pick[:path]).on(json).flatten.first
        to_copy.merge!({ cherry_pick[:key] => raw })
      end
      return to_copy
    end

    def merges
      return [] unless has_merge_paths?
        
      @merges ||= merge_paths.collect {|path|
        ::JsonPath.new(path).on(json).flatten
      }.flatten.compact
    end

    def has_cherry_picks?
      config[:retrieval][:cherryPick]
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

