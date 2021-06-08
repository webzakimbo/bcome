# frozen_string_literal: true

module Bcome
  module Node
    module K8Cluster
      class Subselect < ::Bcome::Node::K8Cluster::Base

        include ::Bcome::Node::KubeCommandHelper
        include ::Bcome::Node::K8Cluster::PathwayRender

        def initialize(*params)
          super
          raise Bcome::Exception::MissingSubselectionKey, @views if !is_grouped_subselect? && !@views[:subselect_from]
          @nodes_loaded = false
        end

        def is_grouped_subselect?
          false
        end

        def nodes_loaded?
          @nodes_loaded 
        end

        def ingresses
          crds["Ingress"]
        end

        def nodes_loaded=(whatever)
          raise 
        end

        def load_nodes
          parent_namespace.load_nodes unless parent_namespace.nodes_loaded?
          update_nodes
          @nodes_loaded = true
        end

        def enabled_menu_items
          (super + %i[logs reload]) - non_k8_menu_items
        end

        def non_k8_menu_items
          %i[get put put_str rsync execute_script ping routes workon enable disable enable! disable!]
        end

        def menu_items
          base_items = super.dup

          base_items[:reload] = {
            description: 'Reload resources',
            console_only: true,
            group: :informational
          }

          base_items[:logs] = {
            description: 'Live tail stdout (all selected pods)',
            group: :informational
          }

          base_items
        end

        def logs(cmd = "")
          resources.active.pmap do |pod|
            pod.logs(cmd)
          end
        end

        def override_pod_identifier?
          respond_to?(:override_identifier) && !override_identifier.nil?
        end

        def k8_cluster
          parent_namespace.k8_cluster
        end

        def hyphenated_identifier
          parent_namespace.hyphenated_identifier
        end

        def machines(skip_for_hidden = true)
          parent_namespace.load_nodes unless parent_namespace.nodes_loaded?
          active_resources = skip_for_hidden ? resources.active : resources.active.reject(&:hide?)

          set = []
          active_resources.each do |resource|
            resource.load_nodes unless resource.nodes_loaded?
            set << resource.machines(skip_for_hidden)
          end

          return set.flatten!
        end
  
        def resources
          @resources ||= do_set_resources
        end

        def update_nodes
          resources.update_nodes(self)
        end

        def do_set_resources
          ::Bcome::Node::Resources::SubselectK8.new(origin_namespace: self, parent_namespace: parent_namespace, filters: filters)
        end

        def run_kc(command)
          parent_namespace.run_kc(command)
        end
  
        def filters
          @views[:filters] || []
        end

        def reload
          do_reload
          other = ::Bcome::Orchestrator.instance.get(keyed_namespace)
          ::Bcome::Workspace.instance.set(current_context: other, context: other)
        end

        def do_reload
          parent_namespace.do_reload
        end

        def k8_namespace 
          parent_namespace.is_a?(::Bcome::Node::K8Cluster::GroupedSubselectK8) ? parent_namespace.parent : parent_namespace  
        end

        private

        def parent_namespace
          @parent_namespace ||= load_parent_namespace
        end

        def load_parent_namespace
          if @views[:subselect_parent] && @views[:subselect_parent].is_a?(::Bcome::Node::Base)
            return @views[:subselect_parent]
          end

          raise ::Bcome::Exception::Generic, "Missing 'subselect_from' attribute on inventory-subselect with config #{@views}" unless @views[:subselect_from]

          parent_crumb = @views[:subselect_from]
          parent = ::Bcome::Node::Factory.instance.bucket[parent_crumb]
 
          unless parent
            # We're lazy loading K8 resources, so we'll need to traverse into the parent namespace
            ::Bcome::Bootup.spider(parent_crumb)
            parent = ::Bcome::Node::Factory.instance.bucket[parent_crumb]           
          end

          raise Bcome::Exception::CannotFindSubselectionParent, "for key '#{parent_crumb}'" unless parent

          unless [::Bcome::Node::K8Cluster::GroupedSubselectK8,::Bcome::Node::K8Cluster::Namespace].include?(parent.class)
            raise Bcome::Exception::Generic, "Subselection target for #{keyed_namespace} must be a K8 Namespace or K8 Grouped subselect"
          end
          parent
        end
      end
    end
  end
end
