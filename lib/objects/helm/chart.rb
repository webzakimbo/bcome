require 'tempfile'

module Bcome::Helm
  class Chart

    def initialize(config)
      @config = config
      @name = @config["name"]
      @repository_name = @config["repository"]
      @version = @config["version"] ? @config["version"] : :latest
      @namespace = @config["namespace"]
      @data_key = @config["data_key"]
      validate
    end

    def apply(node)
      command = "upgrade --install #{@name} #{@repository_name}/#{@name}"
      command += "\s--version #{@version}" unless @version == :latest
      command += "\s--namespace #{@namespace}" if @namespace

      if has_data?
        tempfile = create_data_tempfile(node)
        command += "\s-f #{tempfile.path}"
      end

      runner = node.helm(command)
      tempfile.unlink if tempfile
      raise ::Bcome::Exception::Generic, "Helm install failed" unless runner.is_success?
    end

    def has_data?
      !@data_key.nil?
    end

    def create_data_tempfile(node)
      raw_data = node.metadata.fetch(@data_key)
      tempfile = Tempfile.new("#{Time.now.to_i}")
      tempfile.write(raw_data.to_yaml)     
      tempfile.close
      return tempfile
    end

    private

    def validate
      raise ::Bcome::Exception::Generic, "Missing chart name for Helm chart in chart config '#{@config}'" unless @name
      raise ::Bcome::Exception::Generic, "Missing repository name for Helm chart in chart config '#{@config}'" unless @repository_name
    end  

  end
end
