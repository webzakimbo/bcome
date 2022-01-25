# frozen_string_literal: true

module Bcome::Driver
  class Base
    class << self
      def create_from_config(config, node)
        raise Bcome::Exception::InvalidNetworkDriverType, 'Your network configurtion is invalid' unless config.is_a?(Hash)
        raise Bcome::Exception::InvalidNetworkDriverType, "Missing config parameter 'type' for namespace '#{config.inspect}'" unless config[:type]

        config_klass_key = config[:type].to_sym
        driver_klass = klass_for_type[config_klass_key]
        raise Bcome::Exception::InvalidNetworkDriverType, config unless driver_klass

        driver = driver_klass.new(config, node)
        driver
      end

      def klass_for_type
        {
          ec2: ::Bcome::Driver::Ec2,
          gcp: ::Bcome::Driver::Gcp
        }
      end
    end

    include ::Bcome::LoadingBar::Handler

    def initialize(params, node)
      @params = params
      @node = node
    end

    def matches_auth_config?(other_config)
      # Used to determine whether a particular network configuration merits a new driver, or whether we already
      # have one in memory - along with an authorization - in order to reduce the number of authentication requests

      # For GCP this is overriden, and for AWS todo we'll need to revisit to tweak the default config below.
      config == other_config
    end

    def has_network_credentials?
      false
    end

    def loader_title
      'Loading' + "\s#{pretty_provider_name.bc_blue.bold}\s#{pretty_resource_location.underline}".bc_green
    end

    def loader_completed_title
      'done'
    end

    def pretty_provider_name
      raise 'Should be overriden'
    end

    def pretty_resource_location
      raise 'Should be overidden'
    end

    def network_credentials
      raise 'Should be overidden'
    end

    def config
      @params
    end

    ## Spoof-fetch. Used with the network-socket linkup POC.
    def spoof_fetch_server_list(monkey_patched_inventory)
      if @node.nodes_loaded?
        monkey_patched_inventory.set_static_servers
      else
        wrap_indicator type: :basic, title: loader_title, completed_title: loader_completed_title do
          fake_delay_milliseconds = rand(1..400).to_f / 1000
          sleep fake_delay_milliseconds
          monkey_patched_inventory.set_static_servers
          signal_success
        end
        @node.nodes_loaded!
      end
    end
  end
end
