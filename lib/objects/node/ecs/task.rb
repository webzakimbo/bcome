module Bcome::Node::Ecs
  class Task < Bcome::Node::Base

    attr_reader :arn

    def initialize(*params)
      super
      @nodes_loaded = false
      load_nodes
    end

    def description
      "task iteration ##{iteration}"
    end

    def cluster_name
      return parent.cluster_name
    end

    def fog_client
      parent.fog_client
    end

    def override_server_identifier?
      return true
    end

    def update_identifier(new_identifier)
      @identifier = new_identifier
    end

    def aws_client
      parent.aws_client
    end

    def region
      parent.region
    end

    def credentials_key
      parent.credentials_key
    end

    def logs
      resources.active.pmap do |container|
        container.logs if container.logs_enabled?
      end
    end

    def resources
      @resources ||= ::Bcome::Node::Resources::Ecs.new(self)
    end

    def is_dynamic
      return true
    end  

    def load_nodes
      load_dynamic_nodes unless resources.any?
      nodes_loaded!
    end

    def load_dynamic_nodes
      containers = load_containers
      containers ||= []
      return containers
    end

    def load_containers
      views[:raw_containers].pmap do |cont_config|
        next unless cont_config.has_key?("name")

        container_arn = cont_config["containerArn"]

        next unless ["RUNNING","PENDING"].include?(cont_config["lastStatus"])

        # next unless cont_config["lastStatus"]"RUNNING", "PENDING"]

        resources << ::Bcome::Node::Ecs::Container.new(
          views: {
            identifier: cont_config["name"],
            type: "ecs/container",
            arn: cont_config["containerArn"],
            status: cont_config["lastStatus"],
            definition: container_definition_for_identifier(cont_config["name"]),
          },
          arn: container_arn,
          parent: self
        )
      end
    end

    def definition
      @definition ||= get_definition  
    end

    def get_definition
      response = aws_client.describe_task_definition(:task_definition => identifier)
      return response.task_definition
    end

    def container_definitions
      return definition.container_definitions
    end

    def container_definition_for_identifier(container_identifier)
      return container_definitions.select{|c| c[:name] == container_identifier }.first
    end 

  end
end
