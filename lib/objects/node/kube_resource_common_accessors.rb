module Bcome::Node::KubeResourceCommonAccessors

  def labels
    raw_config_data["metadata"]["labels"]
  end

  def name
    raw_config_data["metadata"]["name"]
  end

end
