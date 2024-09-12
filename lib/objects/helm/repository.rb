module Bcome::Helm
  class Repository

    def initialize(config)
      @name = config["name"]
      @url = config["url"]
      validate
    end

    def helm_bin
      ::Bcome::Helm::Validate::HELM_BINARY
    end  

    def add
      command = "#{helm_bin} repo add #{@name} #{@url}"
      puts "\nRUN\s".bc_green + command
      runner = ::Bcome::Command::Local.run(command)
      raise ::Bcome::Exception::Generic, "Error processing helm command: #{runner.stderr}" unless runner.is_success?
      puts runner.stdout
    end

    private

    def validate
      raise ::Bcome::Exception::Generic, "Missing name for Helm repository #{@config}" unless @name
      raise ::Bcome::Exception::Generic, "Missing url for Helm repository #{@url}" unless @url
    end  

  end
end
