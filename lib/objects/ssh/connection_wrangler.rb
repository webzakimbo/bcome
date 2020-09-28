# frozen_string_literal: true

require 'net/ssh/proxy/jump'

module Bcome::Ssh
  class ConnectionWrangler
    attr_accessor :proxy_details

    def initialize(ssh_driver)
      @ssh_driver = ssh_driver
      @config = ssh_driver.config[:proxy]
      @context_node = ssh_driver.context_node
      @user = ssh_driver.user
      set_proxy_details
    end

    ## Accessors --
    def first_hop
      hops.reverse.first
    end

    def has_hop?
      hops.any?
    end

    def single_hop?
      has_hop? && hops.size == 1
    end

    def proxy
      @proxy ||= create_proxy
    end

    def create_proxy
      proxy = Net::SSH::Proxy::Jump.new(hops.reverse.collect(&:get_ssh_string).join(','))
      proxy
    end

    def get_ssh_command(config = {}, _proxy_only = false)
      cmd = has_hop? ? 'ssh -J' : 'ssh'
      cmd += "\s" + hops.collect(&:get_ssh_string).join(',') if has_hop?
      cmd += "\s#{@ssh_driver.user}@#{target_machine_ingress_ip}"

      config[:as_pseudo_tty] ? "#{cmd} -t" : cmd
    end

    def get_rsync_command(local_path, remote_path)
      cmd = 'rsync -azv'
      cmd += "\s-e 'ssh\s-A -J\s" + hops.collect(&:get_ssh_string).join(',') + "'" if has_hop?
      cmd += "\s#{local_path}\s#{@ssh_driver.user}@#{target_machine_ingress_ip}:#{remote_path}"
      cmd
    end

    def get_local_port_forward_command(start_port, end_port)
      # TODO: - below check is not actually true... you might still want to proxy over SSH...
      raise ::Bcome::Exception::InvalidPortForwardRequest, 'Connections to this node are not via a proxy. Rather than port forward, try connecting directly.' unless has_hop?

      cmd = "ssh -N -L #{start_port}:localhost:#{end_port} -J"
      cmd += "\s" + hops.collect(&:get_ssh_string).join(',') if has_hop?
      cmd += "\s#{@ssh_driver.user}@#{target_machine_ingress_ip}"

      cmd
    end

    def hops
      @hops ||= set_hops
    end

    protected

    def set_proxy_details
      @proxy_details ||= hops.compact.collect(&:proxy_details)
    end

    def target_machine_ingress_ip
      return @context_node.internal_ip_address if @context_node.local_network?

      unless has_hop?
        raise ::Bcome::Exception::InvalidProxyConfig, "missing target ip address for #{@context_node.identifier}. Perhaps you meant to configure a proxy?" unless @context_node.public_ip_address
      end

      has_hop? ? @context_node.internal_ip_address : @context_node.public_ip_address
    end

    private

    def set_hops
      hop_collection = []

      parent = nil
      iterable_configs.each do |config|
        hop = set_proxy_hop(config, parent)
        hop_collection << hop
        parent = hop
      end

      hop_collection.compact
    end

    def set_proxy_hop(config, parent)
      config[:fallback_bastion_host_user] = @ssh_driver.fallback_bastion_host_user
      h = ::Bcome::Ssh::ProxyHop.new(config, @context_node, parent)

      # We don't hop through ourselves
      @context_node.is_same_machine?(h.bcome_proxy_node) ? nil : h
    end

    def iterable_configs
      @iterable ||= if @config
                      @config.is_a?(Hash) ? [@config] : @config
                    else
                      []
                    end
    end
  end
end
