# frozen_string_literal: true

module Bcome::Node::Collection
  class Base < ::Bcome::Node::Base

    def inventories
      inv = []
      @resources.active.each do |r|
        inv << if r.inventory?
                 r
               else
                 r.inventories
               end
      end
      inv.flatten
    end

    def filter_duplicates(original_set)
      instance_lookup = []
      filtered_set = []
      original_set.compact.each do |server|
        unless instance_lookup.include?(server.origin_object_id)
          filtered_set << server
          instance_lookup << server.origin_object_id
        end
      end
      filtered_set
    end

    def do_load_machines(skip_for_hidden = true)
      set = []

      return [] unless @resources

      resources = skip_for_hidden ? @resources.active.reject(&:hide?) : @resources.active

      resources.each do |resource|
        if resource.respond_to?(:load_nodes) && !resource.nodes_loaded?
          resource.load_nodes
          set << resource.resources.active
        else
          set << resource.machines(skip_for_hidden)
        end
      end

      filtered_machines = filter_duplicates(set.flatten)
      filtered_machines
    end

    def collection?
      true
    end
  end
end
