module Helm::ContextualAttributes

  def cluster
    @node.k8_cluster
  end

  def config_path
    ::Bcome::K8Cluster::CommandRunner::BCOME_K8_CONFIG_FILE_PATH
  end

  def context
    cluster.name
  end
end
