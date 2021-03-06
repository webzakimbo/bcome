# frozen_string_literal: true

module Bcome
  module Node
    module Inventory
      class Defined < ::Bcome::Node::Inventory::Base
        include ::Bcome::LoadingBar::Handler

        MACHINES_CACHE_PATH = 'static-cache.yml'

        attr_reader :dynamic_nodes_loaded

        def initialize(*params)
          @load_machines_from_cache = false
          @cache_handler = ::Bcome::Node::CacheHandler.new(self)
          super
        end

        def enabled_menu_items
          super + %i[cache reload]
        end

        def menu_items
          base_items = super.dup

          base_items[:cache] = {
            description: 'Cache the current tree state',
            console_only: false,
            group: :miscellany
          }

          base_items[:reload] = {
            description: "Restock this inventory from remote (hit 'cache' after to persist)",
            console_only: true,
            group: :miscellany
          }
          base_items
        end

        def reload
          resources.reset_duplicate_nodes!
          do_reload
          puts "\n\nDone. Hit 'ls' to see the refreshed inventory.\n".informational
        end

        def set_static_servers
          cached_machines = raw_static_machines_from_cache

          if cached_machines&.any?
            print "\n"
            title = 'Loading' + "\sCACHE".bc_orange.bold + "\s" + namespace.to_s.underline
            wrap_indicator type: :basic, title: title, completed_title: '' do
              cached_machines.each do |server_config|
                resources << ::Bcome::Node::Server::Static.new(views: server_config, parent: self)
              end
              signal_success
            end
          end
        end

        def raw_static_machines_from_cache
          load_machines_config[namespace.to_sym]
        end

        def machines_cache_path
          "#{::Bcome::Node::Factory::CONFIG_PATH}/#{MACHINES_CACHE_PATH}"
        end

        def cache
          @answer = ::Bcome::Interactive::Session.run(self,
                                                      :capture_input, terminal_prompt: 'Are you sure you want to cache these machines (saving will overwrite any previous selections) [Y|N] ? ')

          if @answer && @answer == 'Y'
            cache_nodes_in_memory
            data = load_machines_config

            data.delete(namespace)
            data.delete(namespace.to_sym)

            data[namespace] = views[:static_servers]

            File.open(machines_cache_path, 'w') do |file|
              file.write data.to_yaml
            end
            puts "\nMachines have been cached to #{machines_cache_path} for node #{namespace}".informational
          else
            puts 'Nothing saved'.warning
          end
        end

        def load_machines_config
          config = YAML.load_file(machines_cache_path).deep_symbolize_keys
          config
        rescue ArgumentError, Psych::SyntaxError
          raise Bcome::Exception::InvalidMachinesCacheConfig, 'Invalid yaml in config'
        rescue Errno::ENOENT
          {}
        end

        def cache_nodes_in_memory
          @cache_handler.do_cache_nodes!
        end

        def do_reload
          resources.unset!
          load_dynamic_nodes
        end

        def load_nodes
          set_static_servers
          load_dynamic_nodes unless resources.any?
          nodes_loaded!
        end

        def load_dynamic_nodes
          raw_servers = fetch_server_list

          raw_servers ||= []

          raw_servers.each do |raw_server|
            if raw_server.is_a?(Google::Apis::ComputeBeta::Instance)
              resources << ::Bcome::Node::Server::Dynamic::Gcp.new_from_gcp_instance(raw_server, self)
            elsif raw_server.is_a?(Fog::Compute::AWS::Server)
              resources << ::Bcome::Node::Server::Dynamic::Ec2.new_from_fog_instance(raw_server, self)
            else
              raise Bcome::Exception::UnknownDynamicServerType, "Unknown dynamic server type #{raw_server.class}"
            end
          end

          resources.rename_initial_duplicate if resources.should_rename_initial_duplicate?
        end

        def fetch_server_list
          return [] unless network_driver

          network_driver.fetch_server_list(filters)
        end
      end
    end
  end
end
