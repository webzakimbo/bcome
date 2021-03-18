# frozen_string_literal: true

module Bcome
  module Node
    module K8Cluster
      class GroupedSubselectK8 < Subselect

        include ::Bcome::Node::KubeCommandHelper
 
        def initialize(params)
          super
          @pods_data = params[:pods_data]
          do_set_resources
        end

        def is_grouped_subselect?
          true
        end

        def type
          "group"  
        end

        def description
          identifier
        end

        def list_attributes
          {:"k8/group"=>:identifier}
        end

        def nodes_loaded?
          true
        end

        def k8_namespace
          parent_namespace
        end

        def hyphenated_identifier
          @original_identifier.gsub("_", "-")
        end

        def delegated_kubectl_cmd(command)
          command += " -l 'release=#{hyphenated_identifier}'"
          parent_namespace.delegated_kubectl_cmd(command)
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
