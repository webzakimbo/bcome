# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Container < Bcome::Node::K8Cluster::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeListHelper

    DEFAULT_SHELL = "/bin/sh"

    def initialize(*params)
      super
      @origin_object_id = object_id
      @unreachable = false
    end

    def tree_identifier
      "#{identifier.resource_key} (#{state})"
    end
   
    def is_same_machine?(other)
      origin_object_id == other.origin_object_id
    end

    def is_describable?
      return false
    end

    def machines(*params)
      is_running? ? [self] : []
    end

    def state
      raw_data[:state] || get_state.upcase 
    end

    def get_state
      return state_keys.first if state_keys.is_a?(Array)
      return "unknown"
    end

    def state_keys
      return raw_data["state"].keys if raw_data["state"].is_a?(Hash)
    end 
  
    def is_running?
      state == "RUNNING"
    end   

    def container?
      true
    end   
   
    def type
      "container"
    end

    def list_attributes
      attribs = {
      "k8/#{type}": :identifier,
      "state": :state
      }
      attribs
    end

    def kubectl
       puts "Kubectl is not available from pod level".warning
    end

    def delegated_kubectl_cmd(command)
      command_in_context = "#{command}\s#{hyphenated_identifier}"
      parent.delegated_kubectl_cmd(command_in_context)
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
      (super + %i[logs sh config pseudo_tty]) - non_k8_menu_items
    end

    def menu_items
      base_items = super.dup

      base_items[:sh] = {
        description: 'Enter a shell',
        group: :kubernetes
      }

      base_items[:pseudo_tty] = {
        description: 'Execute a command using an interactive session',
        group: :kubernetes
      }

      base_items[:interactive] = {
        description: 'Execute commands against this container',
        group: :kubernetes,
      }

      base_items
    end
    
    def logs(annotate = false, cmd = "")
      log_command = "logs #{parent.hyphenated_identifier} -c #{hyphenated_identifier} -n #{k8_namespace.hyphenated_identifier} --follow"
      full_log_command = get_kubectl_cmd(log_command)

      full_log_command = "#{full_log_command} | #{cmd}" unless cmd.empty?

      if annotate
        full_log_command = "#{full_log_command} | while read line ; do echo \"#{namespace.terminal_prompt} $line\" ; done"
      end

      system(full_log_command)
    end

    ## Get a shell onto the container--

    def shell(cmd = default_shell)
      shell_cmd = shells[cmd]

      unless shell_cmd
        raise ::Bcome::Exception::Generic, "Could not determine shell for key '#{cmd}'. Please specify one of: '#{shells.keys.join(', ')}'"
      end

      get_shell_command = "#{exec_preamble} #{shell_cmd}" 

      command = get_kubectl_cmd(get_shell_command)
      system(command)
    end
    alias :sh :shell

    def default_shell
      return "sh"
    end

    def shells 
      {
        "bash" => "/bin/bash",
        "ash" => "/bin/ash",
        "sh" => "/bin/sh",
        "dash" => "/bin/dash"
      }
    end

    def form_command_for_container(raw_command)
      "#{exec_preamble} sh '#{raw_command}'"
    end

    def form_pseudo_tty_command_for_container(raw_command)
      "#{exec_preamble} #{raw_command}"
    end

    def form_run_command_for_container(raw_command)
      "#{exec_preamble} #{shells[shell_selection]} -c '#{raw_command}'"
    end

    def shell_selection
      return @shell_selection || default_shell
    end

    def shell_selection=(selection)
      @shell_selection = selection
    end  

    def do_run(commands)
      if commands.is_a?(Array)
        commands.flatten.each do |command|
          run(command)
        end  
      else
        run(commands)
      end 
    end

    def run(*raw_commands)
      runner = exec_run(*raw_commands)
      ## Commands may be run in parallel over many machines (servers and/or containers) at the same time.
      ## We output the command output at the end to prevent interspersing different machines' output.
      runner.print_output
    end

    def exec_run(*raw_commands)
      raw_commands = raw_commands.is_a?(String) ? [raw_commands] : raw_commands
      raise ::Bcome::Exception::MethodInvocationRequiresParameter, "Please specify commands when invoking 'run'" if raw_commands.empty?
      runner = ::Bcome::K8Cluster::ContainerCommand.exec(self, raw_commands)
      ## Commands may be run in parallel over many machines (servers and/or containers) at the same time.
      ## We output the command output at the end to prevent interspersing different machines' output.
      return runner
    end
 
    def pseudo_tty(command)
      get_pseudo_tty_command = form_pseudo_tty_command_for_container(command)
      command = get_kubectl_cmd(get_pseudo_tty_command)
      system(command)
    end

    def exec(args)
      command = "#{exec_preamble} #{args}"
      run_kubectl_cmd(command)     
    end

    def exec_preamble
      "exec -it -n #{k8_namespace.hyphenated_identifier} #{parent.hyphenated_identifier} -c #{hyphenated_identifier} --"
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
  end
end
