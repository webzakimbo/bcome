# frozen_string_literal: true

module Bcome
  class Startup

    def initialize(breadcrumbs, arguments)
      @breadcrumbs = breadcrumbs
      @arguments = arguments
    end

    def do
      case @breadcrumbs
      when '-v', '--version', '--v'
        puts ::Bcome::Version.display
      when 'pack_metadata'
        ::Bcome::Encryptor.instance.pack
      when 'unpack_metadata'
        ::Bcome::Encryptor.instance.unpack
      when 'diff_metadata'
        ::Bcome::Encryptor.instance.diff
      when 'init'
        ::Bcome::Initialization::Factory.do
      else
        bootup
      end
    rescue Bcome::Exception::Base => e
      e.pretty_display
    end

    def bootup
      spawn_into_console = true
      ::Bcome::Bootup.set_and_do({ breadcrumbs: @breadcrumbs, arguments: @arguments }, spawn_into_console)
      clean_up
    rescue ::Bcome::Exception::Base => e
      clean_up
      e.pretty_display
    rescue Excon::Error::Socket => e
      clean_up
      puts "\nNo network access - please check your connection and try again\n".error
    rescue Exception => e
      clean_up
      raise e
    end

    def clean_up
      stop_loading_bars
      close_connections
    end

    def close_connections
      ::Bcome::Bootup.instance.close_ssh_connections
      ::Bcome::Ssh::TunnelKeeper.instance.close_tunnels
      ::Bcome::K8Cluster::ProcessKeeper.instance.kill_pids
    end

    def stop_loading_bars
      ::Bcome::LoadingBar::PidBucket.instance.stop_all
    end
  end
end
