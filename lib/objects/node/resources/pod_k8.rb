# frozen_string_literal: true

module Bcome::Node::Resources
  class PodK8 < Bcome::Node::Resources::Base

    def <<(node)
      if existing_node = for_identifier(node.identifier)
        duplicate_nodes[node.identifier] = duplicate_nodes[node.identifier] ? (duplicate_nodes[node.identifier] + 1) : 2
        count = duplicate_nodes[node.identifier]
        node.identifier = "#{node.identifier}_#{count}"
      end
      @nodes << node
    end

    def duplicate_nodes
      @duplicate_nodes ||= {}
    end
  end
end
