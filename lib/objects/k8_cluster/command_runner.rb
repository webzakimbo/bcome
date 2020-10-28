module Bcome::K8Cluster
  class CommandRunner

    KC_BIN = "kubectl".freeze

    class << self
      def exec(command_suffix)
        runner = new(command_suffix)
        return runner.data
      end
    end
 
    def initialize(command_suffix)
      @command_suffix = command_suffix
    end

    def full_command
      "#{KC_BIN} #{@command_suffix} -o json"
    end

    def data
      @data ||= JSON.parse(result.stdout)    
    end

    private

    def parse_data
      begin
        return JSON.parse(result.stdout)
      rescue TypeError, JSON::ParserError
        # TODO - need to be more informative. What exactly has gone wrong?
        raise ::Bcome::Exception::Generic, "Kubectl parse failed"
      end
    end
  
    def result
      @result ||= ::Bcome::Command::Local.run(full_command)
    end

  end
end
