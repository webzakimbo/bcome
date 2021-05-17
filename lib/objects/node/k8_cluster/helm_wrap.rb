module Bcome::Node::K8Cluster::HelmWrap

  def helm_wrapper
    @helm_wrapper ||= ::Helm::Wrap.new(self)
  end

  def run_helm(command)
    helm_wrapper.run(command)
  end
end

