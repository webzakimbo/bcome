# frozen_string_literal: true

require 'fog/aws'
require 'aws-sdk-core'

module Bcome::Driver
  class Ec2 < Bcome::Driver::Base
    PATH_TO_FOG_CREDENTIALS = '.aws/keys'

    def initialize(*params)
      super
      raise Bcome::Exception::Ec2DriverMissingProvisioningRegion, params.inspect unless provisioning_region
      set_fog_creds_env
    end

    def set_fog_creds_env
      if File.exist?(PATH_TO_FOG_CREDENTIALS)
        ENV['FOG_RC'] = PATH_TO_FOG_CREDENTIALS
      elsif File.exist?(default_creds_path)
        # default credentials are in .ini format, and fog expects YAML
        @credentials = Aws::SharedCredentials.new(profile_name: credentials_key)
      else
        raise ::Bcome::Exception::Ec2DriverMissingAuthorizationKeys, PATH_TO_FOG_CREDENTIALS
      end
    end  

    def default_creds_path
      return File.expand_path("~/.aws/credentials")
    end

    def pretty_provider_name
      'EC2'
    end

    def pretty_resource_location
      @node.network_data[:provisioning_region]
    end

    def fog_compute_client
      @fog_client ||= get_fog_compute_client
    end

    def fog_ecs_client
      @fog_ecs_client ||= get_fog_ecs_client
    end

    def fetch_server_list(legacy_ec2_filters)
      # Filters should be defined within a namespace's :network element. Pre 2.0 the expectation was
      # to define filters at the root level of the namespace. Here we move :filters into :network, yet retain
      # ec2_filters at the root level for backwards compaibility with pre 2.0 versions.
      filters = config.key?(:filters) ? config[:filters] : legacy_ec2_filters

      wrap_indicator type: :basic, title: loader_title, completed_title: loader_completed_title do
        begin
          @servers = unfiltered_server_list.all(filters)
          signal_success
        rescue Exception => e
          signal_failure
          raise e
        end
      end

      @servers
    end

    def fetch_ecs_containers(filters)

      ## LEVEL TWO: First dynamic namespace level: tasks
      task_arns = fog_ecs_client.list_tasks('cluster' => cluster_arn)
      task_arns = task_arns[:body]["ListTasksResult"]["taskArns"]
      task_arn = task_arns.first ## todo - just getting first here as an example
      ## Task should describe itself to auto-populate the node:
      task_details = fog_ecs_client.describe_tasks('cluster' => cluster_arn, 'tasks' => [task_arn])
      ### ...

      # LEVEL THREE: Second dynamic namespace level: containers
      ## Per task, list the containers.
      ## It's on this level that we're going to expose shell & log tails



      # TODO raise if cluster_info empty

      binding.pry
    end

    def unfiltered_server_list
      @unfiltered_server_list ||= fog_compute_client.servers.all({})
    end

    def loading
      fog_client.servers.all({})
    end

    def has_network_credentials?
      true
    end

    def network_credentials
      @network_credentials ||= set_network_credentials
    end
    
    def set_network_credentials
      creds = {
        access_key: raw_fog_credentials['aws_access_key_id'],
        secret_key: raw_fog_credentials['aws_secret_access_key']
      }

      creds[:session_token] = raw_fog_credentials['aws_session_token'] if raw_fog_credentials['aws_session_token']

      return creds
    end

    def raw_fog_credentials
      @raw_fog_credentials ||= YAML.load_file(PATH_TO_FOG_CREDENTIALS)[credentials_key]
    end

    def credentials_key
      @params[:credentials_key]
    end

    def provisioning_region
      @params[:provisioning_region]
    end

    protected

    def get_fog_ecs_client
      return get_fog_client(::Fog::AWS::ECS)
    end


    def get_fog_compute_client
      return get_fog_client(::Fog::Compute)
    end


    def get_fog_client(client_klass)
      ::Fog.credential = credentials_key

      fog_config = {
        provider: 'AWS',
        region: provisioning_region
      }

      if @credentials
        fog_config["aws_access_key_id"] = @credentials.credentials.access_key_id
        fog_config["aws_secret_access_key"] = @credentials.credentials.secret_access_key
        fog_config["aws_session_token"] = @credentials.credentials.session_token
      end

      client = client_klass.new(fog_config)
      return client
    end


  end
end
