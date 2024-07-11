require 'base64'

module Bcome::Node::Ecs
  class Container < Bcome::Node::Base

    def initialize(*params)
      super
      @nodes_loaded = false
    end

    def fog_client
      parent.fog_client
    end

    def aws_client
      parent.aws_client
    end

    def list_attributes
      attribs = super.merge({ "status": :status })
      attribs.delete(:Description)
      return attribs
    end

    ## Logs 

    def log_config
      return definition[:log_configuration]
    end

    def log_group
      log_config[:options]["awslogs-group"]
    end

    def log_stream_prefix
      log_config[:options]["awslogs-stream-prefix"]
    end

    def logs
      command = "aws --profile #{parent.credentials_key} logs tail"
      command += "\s#{log_group} --region #{parent.region}"
      command += "\s--log-stream-name-prefix #{log_stream_prefix} --follow"
      system(command)
    end

    def cluster_name
      return parent.cluster_name
    end

    def run(cmd)
     # response = aws_client.execute_command({
     #   cluster: cluster_name,
     #   task: parent.arn,
     #   container: identifier,
     #   command: cmd,
     #   interactive: true
     # })

     # binding.pry
      raise ::Bcome::Exception::Generic.new "Not yet implemented"
    end

    def shell(cmd = "/bin/sh")
      command = "aws --profile #{parent.credentials_key} ecs execute-command --region #{parent.region}" 
      command += "\s--cluster #{cluster_name} --task #{parent.arn} --container #{identifier}"
      command += "\s--command \"#{cmd}\" --interactive"
      system(command)
    end
  end
end
