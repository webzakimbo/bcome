# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Container < Bcome::Node::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeListHelper

    DEFAULT_SHELL = "/bin/bash"

    def machines
      [self]
    end

    def container?
      true
    end   
   
    def type
      "container"
    end

    def run_kc(command)
      command_in_context = "#{command}\s#{hyphenated_identifier}"
      parent.run_kc(command_in_context)
    end

    def requires_description?
      false
    end

    def k8_namespace
      parent.k8_namespace
    end 

    def enabled_menu_items
      (super + %i[logs shell config pseudo_tty]) - non_k8_menu_items
    end

    def menu_items
      base_items = super.dup
      base_items[:shell] = {
        description: 'Enter a shell',
        group: :ssh
      }
      base_items[:pseudo_tty] = {
        description: 'Execute a command using an interactive session',
        group: :ssh
      }
      base_items[:config] = {
        description: 'Display the k8 configuration for this node',
        group: :informational
      }
      base_items[:logs] = {
        description: 'Live tail STDOUT',
        group: :informational
      }
      base_items
    end
    
    def logs
      log_command = "logs #{parent.hyphenated_identifier} -c #{hyphenated_identifier} -n #{k8_namespace.hyphenated_identifier} --tail 1 --follow"
      full_log_command = get_kubectl_cmd(log_command)
      system(full_log_command)
    end

    ## Get a shell onto the container--

    ## todo: Default shell may be overriden, but should be a configuration option. 
    def shell(cmd = "bash")
      shell_cmd = shells[cmd]

      unless shell_cmd
        raise ::Bcome::Exception::Generic, "Could not determine shell for key '#{cmd}'. Please specify one of: '#{shells.keys.join(', ')}'"
      end

      get_shell_command = form_command_for_container(shell_cmd)

      command = get_kubectl_cmd(get_shell_command)
      system(command)
    end

    ## todo: May be overriden to set alternative shells, but should be a configuration option.
    def shells 
      {
        "bash" => "/bin/bash",
        "ash" => "/bin/ash",
        "sh" => "/bin/sh"
      }
    end

    def form_command_for_container(raw_command)
      "#{exec_preamble} sh -c '#{raw_command}'"
    end

    def run(*raw_commands)
      raw_commands = raw_commands.is_a?(String) ? [raw_commands] : raw_commands
      raise ::Bcome::Exception::MethodInvocationRequiresParameter, "Please specify commands when invoking 'run'" if raw_commands.empty?
      runner = ::Bcome::K8Cluster::ContainerCommand.exec(self, raw_commands)
      ## Commands may be run in parallel over many machines (servers and/or containers) at the same time.
      ## We output the command output at the end to prevent interspersing different machines' output.
      runner.print_output
    end
 
    def pseudo_tty(command)
      get_pseudo_tty_command = form_command_for_container(command)
      command = get_kubectl_cmd(get_pseudo_tty_command)
      system(command)
    end
 
    def exec(args)
      command = "#{exec_preamble} #{args}"
      run_kubectl_cmd(command)     
    end

    def exec_preamble
      "exec -it -n #{k8_namespace.hyphenated_identifier} #{parent.hyphenated_identifier} - container #{hyphenated_identifier} --"
    end

    def run_kubectl_cmd(command)
      return k8_cluster.run_kubectl_cmd(command)
    end

    def get_kubectl_cmd(command)
      return k8_cluster.get_kubectl_cmd(command)
    end

    def k8_cluster
      parent.k8_cluster
    end 

    def ls
      puts "\n" + visual_hierarchy.hierarchy + "\n"
      puts pretty_description
    end
    alias lsa ls

  end
end
