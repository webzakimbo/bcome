# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Container < Bcome::Node::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeListHelper

    DEFAULT_SHELL = "/bin/bash"

    def machines
      [self]
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

    ## Execute an arbitrary command
    def run(args)
      command = form_command_for_container(args)
    
      result = run_kubectl_cmd(command)
      print "\n"
      local_command = result.local_command
      unless local_command.is_success?
        print local_command.stderr
        print "\n" 
      end
    
      print local_command.stdout
      return result
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
