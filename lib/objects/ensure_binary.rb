module Bcome
  class EnsureBinary

    class << self
      def do(bin_name)
        new(bin_name)
      end
    end

    def initialize(bin_name)
      @bin_name = bin_name
    end

    def do
      unless run_which.process_status.exitstatus == 0
        raise ::Bcome::Exception::Generic, "Could not find '#{@bin_name}' in PATH."
      end
    end

    def run_which
      ::Bcome::Command::Local.run("which #{@bin_name}")
    end 

  end
end
