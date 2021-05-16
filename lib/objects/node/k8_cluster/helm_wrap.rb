module Bcome::Node::K8Cluster::HelmWrap

  def helm
    @helm_wrapper ||= ::Helm::Wrap.new(self)
  end

  def run_helm(command)
    helm.run(command)
  end
end

