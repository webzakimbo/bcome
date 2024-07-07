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
      tasks = load_tasks
      tasks ||= []
      return tasks
    end

    def load_tasks
      task_config = fog_client.list_tasks('cluster' => @cluster_arn)    
      task_arns = task_config[:body]["ListTasksResult"]["taskArns"]
      
      task_arns.each do |task_arn|
        detail_response = fog_client.describe_tasks('cluster' => @cluster_arn, 'tasks' => [task_arn])
        full_details = detail_response.data[:body]["DescribeTasksResult"]["tasks"]
        ## Aws send us a load of empty maps for some reason, so let's remove them
        removed_empty = full_details.select{|d| d.keys.any? }

        ## and then, we are left with an array containing two hashes. Weirdly, the keys across both hashes can appear in either in between requests. As they are unique, we can safely merge both maps and get a single data structure. Wtf aws.
        one_map = removed_empty[1].merge(removed_empty[0])

        one_map["taskDefinitionArn"] =~ /arn:aws:ecs:.+:[0-9]+:task-definition\/(.+):([0-9]+)/
        task_definition_name = $1
        task_definition_iteration = $2

        resources << ::Bcome::Node::Ecs::Task.new(
          views: {
            identifier: task_definition_name,
            iteration: task_definition_iteration,
            type: "ecs/task",
            raw_containers: one_map["containers"]
          },  
          parent: self
         )
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
