# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Deployment < Bcome::Node::K8Cluster::Child

    def get_tunnel_command(local_port, remote_port)
      "port-forward deployment/#{name} #{local_port}:#{remote_port} -n #{k8_namespace.hyphenated_identifier}"
    end

    def tunnel(local_port, remote_port)
      puts "\n#{name} is available on http://localhost:#{local_port}".bc_yellow + "\s(ctrl+c to close)"
      tunnel_command = get_tunnel_command(local_port, remote_port)
      
      command = get_kubectl_cmd(tunnel_command)
      runner = ::Bcome::Command::Local.run(command)
      return runner
    end

  end
end
