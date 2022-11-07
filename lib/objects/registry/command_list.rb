# frozen_string_literal: true

module Bcome::Registry
  class CommandList

    include ThreadSafeSingleton

    attr_reader :list

    def initialize
      @list = {}
      @groups_for_nodes = {}
    end

    def add_group_for_node(node, group)
      @groups_for_nodes[node.object_id] = group
    end

    def group_for_node(node)
      @groups_for_nodes[node.object_id]
    end

    def register(node, command_name)
      @list[node.object_id] ? (@list[node.object_id] << command_name) : (@list[node.object_id] = [command_name])
    end

    def command_in_list?(node, command_name)
      @list.key?(node.object_id) && @list[node.object_id].include?(command_name.to_sym)
    end

    def teardown!
      @groups_for_nodes = {}
      @list = {}
    end
  end
end
