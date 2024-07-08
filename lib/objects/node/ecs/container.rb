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

    def cluster_name
      return parent.cluster_name
    end

    def shell(cmd = "/bin/sh")
      begin
        response = aws_client.execute_command({
          cluster: cluster_name,
          task: parent.arn,
          container: identifier,
          command: cmd,
          interactive: true
        }) 
      rescue Exception => e 
        raise ::Bcome::Exception::Generic.new("Could not execute command on container. Is execute command enabled? #{e.message}")
      end

      session_id = response.session.session_id
      cmd = "aws ssm start-session --target #{session_id} --region #{ec2_region}"
      ::Bcome::Command::Local.run(cmd)
    end
  end
end
