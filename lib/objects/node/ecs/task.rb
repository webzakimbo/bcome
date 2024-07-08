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

    def aws_client
      parent.aws_client
    end

    def resources
      @resources ||= ::Bcome::Node::Resources::Base.new(self)
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
 
        resources << ::Bcome::Node::Ecs::Container.new(
          views: {
            identifier: cont_config["name"],
            type: "ecs/container",
            arn: cont_config["containerArn"],
            status: cont_config["lastStatus"]
          },
          arn: container_arn,
          parent: self
        )
      end

    end

  end
end
