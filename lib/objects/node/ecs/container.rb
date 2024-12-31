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

    def override_server_identifier?
      return false
    end

    def config
      pp definition 
    end

    def list_attributes
      attribs = super.merge({ "Status": :status })
      attribs.delete(:Description)
      return attribs
    end

    def env_value_by_name(name)
      env_key = definition.environment.select{|e| e.name == name }
      return (env_key && env_key[0])  ? env_key[0].value : nil
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

    def logs_enabled?
      !definition.nil? && log_config
    end

    def logs
      unless logs_enabled?
        puts "Logs are not enabled for this container".warning 
      else
        if log_config[:options]
          command = aws_log_stream_prefix_command
          system(command)
        elsif log_config.log_driver && log_config.log_driver == "awsfirelens"
            # Infer log group & app name from the associated fluent bit container
            fb_container = parent.container_by_name("fluentbit")
            log_group = fb_container.env_value_by_name("LOG_GROUP_NAME")
            app_name = fb_container.env_value_by_name("APP_NAME")
            log_stream = "#{app_name}/#{task_id}"

            command = aws_log_stream_command(log_group, log_stream)
            system(command)
        else 
          puts "Cannot infer log stream for driver '#{log_config.log_driver}'".warning
        end
      end
    end

    def aws_log_stream_command(log_group_name, log_stream_name)
      command = "aws --profile #{parent.credentials_key} logs tail"
      command += "\s#{log_group_name} --region #{parent.region}"
      command += "\s--log-stream-name-prefix #{log_stream_name} --follow"
      return command
    end

    def aws_log_stream_prefix_command
      command = "aws --profile #{parent.credentials_key} logs tail"
      command += "\s#{log_group} --region #{parent.region}"
      command += "\s--log-stream-name-prefix #{log_stream_prefix} --follow"
      return command
    end

    def cluster_name
      return parent.cluster_name
    end

    def run(cmd)
      execute(cmd)
    end

    def shell(cmd = "/bin/sh")
      execute(cmd)
    end

    def execute(cmd)
      command = "aws --profile #{parent.credentials_key} ecs execute-command --region #{parent.region}"
      command += "\s--cluster #{cluster_name} --task #{parent.arn} --container #{identifier}"
      command += "\s--command \"#{cmd}\" --interactive"
      system(command)
    end
  end
end
