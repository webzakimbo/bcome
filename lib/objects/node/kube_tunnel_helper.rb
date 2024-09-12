module Bcome::Node::KubeTunnelHelper

  def form_tunnel_command(local_and_remote_port)
    "port-forward #{shorthand}/#{hyphenated_identifier} #{local_and_remote_port} -n #{k8_namespace.hyphenated_identifier}"
  end

  def tunnel(local_and_remote_port)
    raise ::Bcome::Exception::Base, "Missing method #{shorthand}" unless respond_to?(:shorthand)

    puts "\nForwarding localhost:#{local_and_remote_port}".informational
    puts "CTRL+C to close\n"
    get_tunnel_command = form_tunnel_command(local_and_remote_port)
    puts get_tunnel_command
    command = get_kubectl_cmd(get_tunnel_command)
    runner = ::Bcome::Command::Local.run(command)
    return runner
  end

end
