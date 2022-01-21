# frozen_string_literal: true

module Bcome
  module Node
    module K8Cluster
      class GroupedSubselectK8 < Subselect

        include ::Bcome::Node::KubeCommandHelper
        include ::Bcome::Node::K8Cluster::ResourceMappings
        include ::Bcome::Node::K8Cluster::PathwayRender
 
        def initialize(params)
          super
          @data = params[:data]
          @grouped_by_label = params[:grouped_by_label]
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

        def run_kubectl_cmd(command)
           k8_namespace.run_kubectl_cmd(command)
        end

        def k8_namespace
          parent_namespace
        end

        def do_set_resources(items = @data)
          items.each do |item|
            resource_type = item["kind"]
            resource_klass = resource_klasses[resource_type]
            resource_klass = crd_resource_klass unless resource_klass
            add_resource(resource_klass, resource_type, item)
          end
          return
        end

        def ingresses
          crds["Ingress"]
        end

        def hyphenated_identifier
          @original_identifier.gsub("_", "-")
        end

        def run_kc(command)
          command_in_context = "#{command} -l '#{@grouped_by_label}=#{hyphenated_identifier}'" if should_add_selector?(command)
          parent.run_kc(command_in_context)
        end

        def should_add_selector?(command)
          # command is a 'get', but name has not been provided
          command =~ /^get.+/ && command !~ /(get)\s+([a-zA-Z]+)\s+([a-z0-9]([-a-z0-9]*[a-z0-9]))?/
        end

        def delegated_kubectl_cmd(command)
          if hyphenated_identifier != "ungrouped"
            command += " -l '#{@grouped_by_label}=#{hyphenated_identifier}'" if should_add_selector?(command)
          end

          parent_namespace.delegated_kubectl_cmd(command)
        end

        def resources
          @resources ||= ::Bcome::Node::Resources::Base.new
        end
      end
    end
  end
end
