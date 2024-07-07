module Bcome::Node::Ecs
  class Cluster < Bcome::Node::Base

    def initialize(*params)
      super
      @nodes_loaded = false
      initialize_cluster_node
    end

    def fog_client
      network_driver.fog_ecs_client
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
      raw_tasks = load_tasks
      raw_tasks ||= []
      return raw_tasks
    end

    def load_tasks
      task_config = fog_client.list_tasks('cluster' => @cluster_arn)    
      task_arns = task_config[:body]["ListTasksResult"]["taskArns"]
      
      task_arns.each do |task_arn|
        resources << ::Bcome::Node::Ecs::Task.new(task_arn)
      end
    end

    def initialize_cluster_node
      @cluster_name = views[:cluster][:name]
      raise ::Bcome::Exception::InvalidEcsClusterConfig.new "Config is missing cluster name" if @cluster_name.nil?
      @cluster_info = fog_client.describe_clusters('clusters' => @cluster_name)
      clusters_config = @cluster_info.data[:body]['DescribeClustersResult']['clusters']

      unless clusters_config.any?
        raise ::Bcome::Exception::InvalidEcsClusterConfig.new "Cannot find cluster named #{@cluster_name}"
      end

      @cluster_arn = clusters_config.first['clusterArn']

      unless @cluster_arn
        raise ::Bcome::Exception::InvalidEcsClusterConfig.new "Cannot retrieve cluster arn for cluster named #{@cluster_name}"
      end
    end

  end
end
