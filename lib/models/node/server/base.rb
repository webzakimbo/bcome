module Bcome::Node::Server
  class Base < Bcome::Node::Base

    def type
      "server"
    end

    def machines
      [self]
    end

    def server?
      true
    end

    def requires_description?
      false
    end

    def requires_type?
      false
    end

    def enabled_menu_items
      (super + [:ssh]) - [:enable, :disable, :enable!, :disable!]
    end

    def ssh
      ssh_driver.do_ssh
    end

    def put(local_path, remote_path)
      ssh_driver.put(local_path, remote_path)
    end

    def get(remote_path, local_path)
      ssh_driver.get(remote_path, local_path)
    end

    def ls
      puts "\n" + visual_hierarchy.bc_orange + "\n"
      puts pretty_description
    end

    def ping
      ping_result = ssh_driver.ping
      print_ping_result(ping_result)
    end

    def print_ping_result(ping_result = { success: true })
      result = {
        namespace => {
          "connection" => ping_result[:success] ? "success" : "failed",
          "ssh_config" => ssh_driver.pretty_config_details
        }
      }

      unless ping_result[:success]
        result[namespace]["error"] = ping_result[:error].message
      end

      colour = ping_result[:success] ? :green : :red

      ap result, {
        :color => {
           hash:  colour,
           symbol: colour,
           string: colour,
           keyword: colour,
           variable: colour,
           array: colour
        }
      }
    end

    def list_attributes
      attribs = {
        "identifier": :identifier,
        "internal ip": :internal_ip_address,
        "public ip": :public_ip_address,
      }

      attribs.merge!("description": :description ) if has_description?
      attribs
    end

    def cache_data
      d = { identifier: identifier }
      d[:internal_ip_address] = internal_ip_address if internal_ip_address
      d[:public_ip_address] = public_ip_address if public_ip_address
      d[:description] = description if description
      d
    end

    def do_run(raw_commands)
      raw_commands = raw_commands.is_a?(String) ? [raw_commands] : raw_commands
      commands = raw_commands.collect{|raw_command| ::Bcome::Ssh::Command.new({ :node => self, :raw => raw_command }) }
      command_exec = ::Bcome::Ssh::CommandExec.new(commands)
      command_exec.execute!
      return commands
    end

    def has_description?
      !@description.nil?
    end

    def static_server?
      false
    end

    def dynamic_server?
      !static_server?
    end

  end  
end
