module Bcome::Node::K8Cluster::Selector

  def selected
    @selected ||= get_selected
  end

  def get_selected(potentials = candidates)
    return [] if potentials.nil?

    potentials.select{|potential|
      candidate_data = potential.raw_data 

      matches = selector.collect{|key, value|
        path = JsonPath.new("metadata.labels.'#{key}'")
        path_data = path.on(candidate_data).first
        path_data == value
      }

     !matches.include?(false)
    }
  end

  def candidates
    raise ::Bcome::Exception::Generic, "Misconfiguration: missing selector_kind" unless respond_to?(:selector_kind)
    parent.crds[selector_kind]
  end

  def selector
    spec ? spec["selector"] : raw_data["selector"]
  end

  def path_values
    selector.values
  end
end
