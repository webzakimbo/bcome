# frozen_string_literal: true

module Bcome::Helm
  class Wrap

    include Validate
    include ContextualAttributes

    def initialize(node)
      @node = node
      validate
    end

    def helm_bin
      ::Bcome::Helm::Validate::HELM_BINARY
    end 

    def run(command, skip_output = false)
      cmd = contextualized_command(command)

      puts "\nRUN\s".bc_green + cmd unless ::Bcome::Orchestrator.instance.command_output_silenced? 
 
      runner = ::Bcome::Command::Local.run(cmd)
      parse_runner(runner)
      return runner
    end

    def contextualized_command(command)
      cmd = "#{helm_bin} #{command} #{context_string}"
      verb = command.split("\s").first                                                            
      cmd += "\s" + namespace_flag(command) if namespace_commands.include?(verb)
      cmd
    end 

    def namespace_commands
      %w(ls install uninstall get)
    end  

    def namespace_flag(command)
      return "--namespace #{@node.identifier}" unless is_collection?
      return "--all-namespaces" if add_all_namespaces_flag?(command)
      return ""
    end

    def add_all_namespaces_flag?(command)
      is_collection? && (command =~ /^get.+/).nil?
    end


    def context_string
      "--kubeconfig=#{config_path} --kube-context=#{context}"
    end

    def parse_runner(runner)
      if runner.is_success?
        puts runner.stdout
      elsif runner.stderr =~ /kubernetes cluster unreachable/i
        @node.k8_cluster.reauthorize!
      else
        puts "error processing Helm command".error
        puts "\n#{runner.stderr}\n"
      end
    end
  end
end
