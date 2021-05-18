module Bcome::Helm
  class Chart

    def initialize(config)
      @config = config
      @name = @config["name"]
      @repository_name = @config["repository"]
      @version = @config["version"] ? @config["version"] : :latest
      validate
    end

    def apply(node)
      command = "upgrade --install #{@name} #{@repository_name}/#{@name}"
      command += "\s--version #{@version}" unless @version == :latest
      runner = node.helm(command)
      raise ::Bcome::Exception::Generic, "Helm install failed" unless runner.is_success?
    end

    private

    def validate
      raise ::Bcome::Exception::Generic, "Missing chart name for Helm chart in chart config '#{@config}'" unless @name
      raise ::Bcome::Exception::Generic, "Missing repository name for Helm chart in chart config '#{@config}'" unless @repository_name
    end  

  end
end
