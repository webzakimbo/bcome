module Bcome::Node::K8Cluster::HelmWrap

  def helm_wrapper
    @helm_wrapper ||= ::Bcome::Helm::Wrap.new(self)
  end

  def run_helm(command)
    runner = helm_wrapper.run(command)
    return runner
  end
end

