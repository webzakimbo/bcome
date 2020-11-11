# frozen_string_literal: true

module Bcome::Node::Resources
  class SubselectK8 < Bcome::Node::Resources::Base

    def initialize(config)
      @config = config
      super
      run_subselect
    end

    def run_subselect
      parent_namespace.load_nodes unless parent_namespace.nodes_loaded?
      new_set = parent_namespace.resources.nodes

      new_set = filter_by_label(new_set)

      @nodes = new_set
    end

    def update_nodes(k8_subselect_node)
      new_set = []

      @nodes.collect do |node|
        new_node = node.dup_with_new_parent(k8_subselect_node)
        set_overrides(k8_subselect_node, new_node)

        # Register the new node with the registry
        ::Bcome::Registry::Loader.instance.set_command_group_for_node(new_node)

        new_set << new_node
      end
      @nodes = new_set
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

    def filter_labels
      @config[:labels]
    end

    def filter_by_label(nodes)
       
      filtered_nodes = []

      filter_labels.each do |key, values|
        filtered_nodes = nodes.select {|node| node.k8_labels[key.to_s] && values.include?(node.k8_labels[key.to_s]) }
      end
  
      filtered_nodes
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
