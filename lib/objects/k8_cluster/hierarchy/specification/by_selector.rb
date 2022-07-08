module Bcome::K8Cluster::Hierarchy::Specification
  class BySelector < Base

    def do_set_resources

      return if selectors.nil? || selectors.empty?

      resource = parent.get_selected(candidates).first

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

    def selectors
      ::JsonPath.new("spec.selector").on(source_json).first
    end

    def is_valid_specification?
      config[:resource]  
    end
  end
end

