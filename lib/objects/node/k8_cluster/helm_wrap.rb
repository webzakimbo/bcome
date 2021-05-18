module Bcome::Node::K8Cluster::HelmWrap

  def helm_wrapper
    @helm_wrapper ||= ::Bcome::Helm::Wrap.new(self)
  end

  def run_helm(command, skip_output = false)
    runner = helm_wrapper.run(command, skip_output)
    return runner
  end
end

