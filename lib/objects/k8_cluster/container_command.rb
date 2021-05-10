module Bcome::K8Cluster
  class ContainerCommand

    class << self
      def exec(container, commands)
        runner = new(container, commands)
        runner.execute!
        runner
      end  
    end

    def initialize(container, commands)
      @container = container
      @commands = commands
    end

    def output_append(output_string)
      @output_string = "#{@output_string}#{output_string}"
    end

    def log_window
      ::Bcome::Ssh::Window.instance
    end

    def print_output
      print "#{@output_string}\n\n"
    rescue StandardError
      puts "Could not print #{@output_string.inspect}"
    end

    def execute!
      @commands.each do |command|
        # Get the fully formed command that we're going to pass to kubectl
        kube_command = @container.form_command_for_container(command)

        output_append("\n(#{@container.namespace})$".terminal_prompt + ">\s#{command}\n\n")
        result = @container.run_kubectl_cmd(kube_command)

        local_command = result.local_command
        unless local_command.is_success?
          output_append(local_command.stderr + "\n")
        end

        output_append(local_command.stdout)
      end
    end 


  end
end
