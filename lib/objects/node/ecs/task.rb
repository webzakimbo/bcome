module Bcome::Node::Ecs
  class Task < Bcome::Node::Base

    def initialize(*params)
      super
      @nodes_loaded = false
      load_nodes
    end

    def description
      "task iteration ##{iteration}"
    end

    def fog_client
      parent.fog_ecs_client
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
      binding.pry

    end

  end
end
