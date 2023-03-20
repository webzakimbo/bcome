# frozen_string_literal: true

module Bcome::Node::Resources
  class Base
    include Enumerable

    attr_accessor :nodes

    def initialize(*_params)
      @nodes = []
      @disabled_resources = []
    end

    def wipe!
      @nodes = []
      @disables_resources = []
    end

    def each
      @nodes.each { |node| yield(node) }
    end

    def <<(node)
      existing_node = for_identifier(node.identifier)

      if existing_node
        if existing_node.is_a?(::Bcome::Node::K8Cluster::Base)
          # If a node is a kubernetes resource, we'll swap out for the latest one, otherwise, we cannot assume it's the same object and must raise.
          @nodes -= [existing_node]
        else
          exception_message = "#{node.identifier} #{node.is_a?(::Bcome::Node::K8Cluster::Base)} is not unique within namespace #{node.parent.namespace}"
          raise Bcome::Exception::NodeIdentifiersMustBeUnique, exception_message
        end
      end
      @nodes << node
    end

    def should_rename_initial_duplicate?
      false
    end

    def clear!
      @disabled_resources = []
    end
    alias enable! clear!

    def unset!
      @nodes = []
    end

    def do_disable(identifiers)
      identifiers.each { |id| disable(id) }
      return
    end

    def do_enable(identifiers, reset = true)
      resources = identifiers.collect{|id|
        resource = for_identifier(id)
        raise Bcome::Exception::NoNodeNamedByIdentifier, id unless resource
        resource
      }    
      # clear all selections...
      disable! if reset

      # ...and replace with whatever the user wants to workon
      resources.collect{|resource| 
        @disabled_resources -= [resource]
      }
      return
    end

    def disable!
      @disabled_resources = @nodes
    end

    def disable(identifier)
      resource = for_identifier(identifier)
      raise Bcome::Exception::NoNodeNamedByIdentifier, identifier unless resource

      @disabled_resources << resource unless @disabled_resources.include?(resource)
    end

    def enable(identifier)
      resource = for_identifier(identifier)
      raise Bcome::Exception::NoNodeNamedByIdentifier, identifier unless resource

      @disabled_resources -= [resource]
    end

    def clear!
      @disabled_resources = []
      nil
    end

    def active
      return @nodes - @disabled_resources
    end

    def is_active_resource?(resource)
      # node identifiers are unique within a namespace. This must be used rather than the old
      # active.include?(resource) due to kubernetes use cases where we may have focused on an alternative
      # resource, thus swapping out the initial tree view in the UI.
      active.collect(&:identifier).include?(resource.identifier)
    end

    def for_identifier(identifier)
      identifier = $1 if identifier =~ /^'(.+)'$/
      resource = @nodes.select { |node| node.identifier == identifier }.last
      resource
    end

    def empty?
      @nodes.empty?
    end

    def has_active_nodes?
      active.any?
    end

    def size
      @nodes.size
    end

    def first
      @nodes.first
    end
  end
end
