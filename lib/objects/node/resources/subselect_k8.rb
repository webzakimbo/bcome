# frozen_string_literal: true

module Bcome::Node::Resources
  class SubselectK8 < Bcome::Node::Resources::Base

    def initialize(config)
      @config = config
      super
      @new_set = []
      run_subselect
    end

    def run_subselect
      parent_namespace.load_nodes unless parent_namespace.nodes_loaded?
      new_set = parent_namespace.resources.nodes

      new_set = filter(new_set)

      @nodes = new_set
    end

    def update_nodes(k8_subselect_node)
      @nodes.collect do |node|
        new_node = node.dup_with_new_parent(k8_subselect_node)
        set_overrides(k8_subselect_node, new_node)

        if existing_node = for_identifier(new_node.identifier)
          duplicate_nodes[new_node.identifier] = duplicate_nodes[new_node.identifier] ? (duplicate_nodes[new_node.identifier] + 1) : 2
          count = duplicate_nodes[new_node.identifier]
          new_node.identifier = "#{new_node.identifier}_#{count}"
        end

        # Register the new node with the registry
        ::Bcome::Registry::Loader.instance.set_command_group_for_node(new_node)

        @new_set << new_node
      end

      rename_initial_duplicate

      @nodes = @new_set
    end

    def for_identifier(identifier)
      resource = @new_set.select { |node| node.identifier == identifier }.last
      resource
    end

    def rename_initial_duplicate
      duplicate_nodes.each do |node_identifier, _count|
        node = for_identifier(node_identifier)
        node.identifier = "#{node.identifier}_1"
      end
    end

    def duplicate_nodes
      @duplicate_nodes ||= {}
    end

    def set_overrides(k8_subselect_node, node)
      override_pod_identifier(k8_subselect_node, node)
    end

    def override_pod_identifier(k8_subselect_node, node)
      if k8_subselect_node.override_pod_identifier?
        node.identifier =~ /#{k8_subselect_node.override_identifier}/
        node.update_identifier(Regexp.last_match(1)) if Regexp.last_match(1)
      end
    end

    def filters
      @config[:filters]
    end

    def filter(nodes)
      filtered_nodes = nodes.select{|node| node.matches_filters?(filters) }
      return filtered_nodes
    end

    def parent_crumb
      @config[:parent_crumb]
    end

    def filters
      @config[:filters]
    end

    def parent_namespace
      @config[:parent_namespace]
    end

    def origin_namespace
      @config[:origin_namespace]
    end
  end
end
