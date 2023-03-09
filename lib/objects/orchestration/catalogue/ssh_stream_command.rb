module Bcome::Orchestration::Catalogue
  class SshStreamCommand < Bcome::Orchestration::Base

    def execute
      ::Bcome::Orchestrator.instance.tail_all_command_output!(@node)
      stream
    end

    def stream
      target_selector ? targets.each {|server| server.run(command) } : @node.run(command)
    end

    def command
      @arguments[:command]
    end

    def target_selector
      @arguments[:target_selector]
    end

    def targets
      return @node.resources.select{|n| n.identifier =~ /#{target_selector}/ } if target_selector
      return []
    end

    def app_servers
      @app_servers ||= @node.resources.select{|n| n.identifier =~ /app/}
    end

  end
end
