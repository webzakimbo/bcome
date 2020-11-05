module Bcome::Node::KubeCommandHelper

  def run(command)
    machines.pmap do |machine|
      machine.run(command)
    end
  end

end
