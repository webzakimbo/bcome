module ::Bcome::Node::K8Cluster
  class HierarchySchema

    include ThreadSafeSingleton

    FILE_PATH="bcome/k8_hierarchy.yml"

    def schema
      @hierarchy_schema ||= do_load_hierarchy_schema
    end
  
    def do_load_hierarchy_schema
      raise ::Bcome::Exception::Generic, "\nMissing k8 hierarchy config at '#{FILE_PATH}'. Run 'bcome init' from your project root to auto-genenerate this file" unless File.exists?(FILE_PATH)
  
      begin
        return YAML.load_file(FILE_PATH)
      rescue Psych::SyntaxError => e
        raise Bcome::Exception::InvalidK8HierarchyConfig, "Error: #{e.message}"
      end
    end
  end
end
