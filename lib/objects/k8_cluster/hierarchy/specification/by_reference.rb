module Bcome::K8Cluster::Hierarchy::Specification
  class ByReference < Base

    def do_set_resources
      reference_value = ::JsonPath.new(config[:retrieval][:reference]).on(source_json)

      return if reference_value.empty?

      resource_name = reference_value.first

      resource = candidates.select {|candidate|
        candidate.identifier == resource_name    
      }.first

      return unless resource

      add_resource(resource)
    end

    def validate
      raise ::Bcome::Exception::Generic, "Invalid k8 cluster hierarchy config #{config}" unless is_valid_specification?
    end

    def candidates
      @candidates ||= @element.tree.selection_pool.select{|candidate| candidate.type == config[:resource] }
    end

    def source_json
      parent.raw_data
    end  

    def is_valid_specification?
      config[:resource] && config[:retrieval] && config[:retrieval][:reference] 
    end
  end
end

