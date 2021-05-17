# frozen_string_literal: true

module Helm
  class Wrap

    include Helm::Validate
    include Helm::ContextualAttributes

    def initialize(node)
      @node = node
      validate
    end

    def run(command)
      cmd = contextualized_command(command)
      #puts cmd
      runner = ::Bcome::Command::Local.run(cmd)
      parse_runner(runner)
    end

    def contextualized_command(command)
      cmd = "#{::Helm::Validate::HELM_BINARY} #{command} #{context_string}"
      cmd += "\s" + namespace_flag if namespace_commands.include?(command)
      cmd
    end 

    def namespace_commands
      %w(ls)
    end  

    def namespace_flag
      is_collection? ? "--all-namespaces" : "--namespace #{@node.identifier}"
    end
 
    def context_string
      "--kubeconfig=#{config_path} --kube-context=#{context}"
    end

    def parse_runner(runner)
      if runner.is_success?
        puts runner.stdout
      else
        puts "error processing Helm command".error
        puts "\n#{runner.stderr}\n"
      end 
    end
  end
end
