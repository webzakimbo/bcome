# frozen_string_literal: true

module Bcome
  module Node
    module K8Cluster
      class Subselect < ::Bcome::Node::Base

        include ::Bcome::Node::KubeCommandHelper

        def initialize(*params)
          super
          raise Bcome::Exception::MissingSubselectionKey, @views unless @views[:subselect_from]

          update_nodes
        end

        def nodes_loaded?
          true
        end
 
        def enabled_menu_items
          super + %i[reload]
        end

        def menu_items
          base_items = super.dup

          base_items[:reload] = {
            description: 'Reload this namespace subselect',
            console_only: true,
            group: :miscellany
          }
          base_items
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
          ::Bcome::Node::Resources::SubselectK8.new(origin_namespace: self, parent_namespace: parent_namespace, labels: labels)
        end

        def run_kc(command)
          parent_namespace.run_kc(command)
        end
  
        def nodes_loaded?
          true
        end

        def filters
          @views[:sub_filter] || @views[:filters] || {}
        end

        def reload
          do_reload
        end

        def do_reload
          raise "TODO"
          #parent_namespace.resources.reset_duplicate_nodes!
          #parent_namespace.do_reload
          #resources.run_subselect
          #update_nodes
          nil
        end

        private

        def parent_namespace
          @parent_namespace ||= load_parent_namespace
        end

        def load_parent_namespace
          raise ::Bcome::Exception::Generic, "Missing 'subselect_from' attribute on inventory-subselect with config #{@views}" unless @views[:subselect_from]

          parent_crumb = @views[:subselect_from]
          parent = ::Bcome::Node::Factory.instance.bucket[parent_crumb]
          raise Bcome::Exception::CannotFindSubselectionParent, "for key '#{parent_crumb}'" unless parent
          raise Bcome::Exception::Generic, "Subselection target for #{keyed_namespace} must be a K8 Namespace" unless parent.is_a?(::Bcome::Node::K8Cluster::Namespace)
          parent
        end
      end
    end
  end
end
