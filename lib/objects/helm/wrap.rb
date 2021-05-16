module Helm
  class Wrap

    include Helm::Validate
    include Helm::ContextualAttributes

    def initialize(node)
      @node = node
      validate
    end

    def run(command)
      wrapped_command = wrap(command)
      runner = ::Bcome::Command::Local.run(wrapped_command)
      parse_runner(runner)
    end

    private

    def wrap(command)
      "#{::Helm::Validate::HELM_BINARY} #{command} --kubeconfig=#{config_path} --kube-context=#{context}"  
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
