# frozen_string_literal: true

module Bcome
  module Node
    module K8Cluster
      class GroupedSubselectK8 < Subselect

        def initialize(params)
          super
          @pods_data = params[:pods_data]
        end
  
        def is_grouped_subselect?
          true
        end

        def description
          "TODO - skip this"
        end

        def type
          "TODO - skip this"
        end

        def do_set_resources
          @pods_data.each do |pod_data|
            pod_identifier = pod_data["metadata"]["name"]

            namespace_config = {
               identifier: pod_identifier,
               raw_data: pod_data
             } 
            pod = ::Bcome::Node::K8Cluster::Pod.new(views: namespace_config, parent: self)     
            resources << pod
            pod.set_containers
            ::Bcome::Node::Factory.instance.bucket[pod.keyed_namespace] = pod
          end

          return resources
        end

        def resources
          @resources ||= ::Bcome::Node::Resources::Base.new
        end

      end
    end
  end
end
