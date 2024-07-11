# frozen_string_literal: true

module Bcome::Node::Resources
  class Ecs < Bcome::Node::Resources::Base

    def initialize(cluster)
      @cluster = cluster
      super
    end

    def override_server_identifier(cluster, node)
      if cluster.override_server_identifier?
        node.identifier =~ /#{cluster.override_identifier}/
        node.update_identifier(Regexp.last_match(1)) if Regexp.last_match(1)
      end
    end

    def <<(node)
      if existing_node = for_identifier(node.identifier)
        duplicate_nodes[node.identifier] = duplicate_nodes[node.identifier] ? (duplicate_nodes[node.identifier] + 1) : 2
        count = duplicate_nodes[node.identifier]
        node.identifier = "#{node.identifier}_#{count}"
      end
      @nodes << node
    end

    def should_rename_initial_duplicate?
      true
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

    def reset_duplicate_nodes!
      @duplicate_nodes = {}
    end

  end
end
