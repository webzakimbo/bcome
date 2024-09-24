module Bcome::Node::Ecs
  class Cluster < Bcome::Node::Base

    include ::Bcome::LoadingBar::Handler

    attr_reader :cluster_name

    def initialize(*params)
      super
      @nodes_loaded = false
      initialize_cluster_node
    end

    def fog_client
      network_driver.fog_ecs_client
    end

    def aws_client
      network_driver.aws_ecs_client
    end

    def identifier_override_set?
      respond_to?(:override_identifier) && !override_identifier.nil?
    end  

    def region
      return network_data[:provisioning_region]
    end

    def credentials_key
      return network_driver.credentials_key
    end

    def resources
      @resources ||= ::Bcome::Node::Resources::Ecs.new(self)
    end

    def reload
      resources.reset_duplicate_nodes!
      do_reload
      puts "\n\nDone. Hit 'ls' to see the refreshed inventory.\n".informational
    end

    def do_reload
      resources.unset!
      load_dynamic_nodes
    end

    def is_dynamic
      return true
    end  

    def logs
      resources.active.pmap do |task|
        task.logs
      end
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
      
      title = 'Loading' + "\sECS".bc_blue.bold + "\s" + namespace.to_s.underline
      wrap_indicator type: :basic, title: title, completed_title: '' do

        task_arns.pmap do |task_arn|
          # Retrieve cluster & task details
          detail_response = fog_client.describe_tasks('cluster' => @cluster_arn, 'tasks' => [task_arn])
          full_details = detail_response.data[:body]["DescribeTasksResult"]["tasks"]

          # Cleanup dirty AWS data structure
          removed_empty = full_details.select{|d| d.keys.any? }
          one_map = removed_empty[1].merge(removed_empty[0])

          # Derive node name        
          one_map["taskDefinitionArn"] =~ /arn:aws:ecs:.+:[0-9]+:task-definition\/(.+):([0-9]+)/
          task_definition_name = $1
          task_definition_iteration = $2

          # Set task resources
          resources << ::Bcome::Node::Ecs::Task.new(
            views: {
              identifier: task_definition_name,
              iteration: task_definition_iteration,
              type: "ecs/task",
              raw_containers: one_map["containers"],
              arn: task_arn,
            }, 
            parent: self
           )
        end
        signal_success
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
