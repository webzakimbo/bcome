module Bcome::Node::KubeCommandHelper

  def run(command)
    running_machines.pmap do |machine|
      machine.run(command)
    end
  end

  def running_machines
    return machines.select{|machine| machine.state == "RUNNING" }
  end

end
