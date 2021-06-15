module Bcome::Node::K8Cluster::Selector

  def selected
    @selected ||= get_selected
  end

  private

  def get_selected
    raise ::Bcome::Exception::Generic, "Misconfiguration: a class including Selector must have defined a selector_kind" unless respond_to?(:selector_kind)

    return [] if candidates.nil?

    candidates.select{|candidate|
      candidate_data = candidate.raw_data 

      matches = selector.collect{|key, value|
        path = JsonPath.new("metadata.labels.'#{key}'")
        path_data = path.on(candidate_data).first
        path_data == value
      }

     !matches.include?(false)
    }
  end

  def candidates
    parent.crds[selector_kind]
  end

  def selector
    spec["selector"]
  end

  def path_values
    selector.values
  end
end
