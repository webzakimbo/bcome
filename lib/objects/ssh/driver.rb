# frozen_string_literal: true

require 'net/scp'

module Bcome::Ssh
  class Driver
    attr_reader :config, :context_node

    include Bcome::Ssh::DriverConnection
    include Bcome::Ssh::DriverFunctions
    include Bcome::Ssh::DriverUser
    include Bcome::Ssh::DriverCommandStrings

    def initialize(config, context_node)
      @config = config
      @context_node = context_node
    end

    def connection_wrangler
      @connection_wrangler ||= set_connection_wrangler
    end

    def proxy_chain
      @proxy_chain ||= ::Bcome::Ssh::ProxyChain.new(connection_wrangler)
    end

    def set_connection_wrangler
      @connection_wrangler = ::Bcome::Ssh::ConnectionWrangler.new(self)
    end

    def pretty_ssh_config
      xconfig = {
        user: user,
        timeout: timeout_in_seconds
      }

      if has_proxy?
        xconfig[:proxy] = connection_wrangler.proxy_details
      else
        xconfig[:host_or_ip] = node_host_or_ip
      end

      xconfig
    end

    def proxy_config_value
      @config[:proxy]
    end

    def multi_hop_proxy_config
      @config[:multi_hop_proxy]
    end

    def has_multi_hop_proxy?
      !multi_hop_proxy_config.nil?
    end

    def has_proxy?
      return connection_wrangler.has_hop?
    end
  end
end
