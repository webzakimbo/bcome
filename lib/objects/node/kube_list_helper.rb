module Bcome::Node::KubeListHelper

  def list_attributes
    @attribs ||= set_list_attributes
  end

  def set_list_attributes
    attribs = {
      "k8/#{type}": :identifier,
    }

    attribs
  end

  def description
    identifier
  end

end
