module Bcome::Node::Factory
  CONFIG_PATH = 'config/bcome/estate.yml'.freeze
  INVENTORY_KEY = 'inventory'.freeze
  COLLECTION_KEY = 'collection'.freeze

  class << self
    def init_tree
      create_node(load_estate_config)
    end

    def create_tree(context_node, views)
      views.each { |config| create_node(config, context_node) }
    end

    def create_node(config, parent = nil)
      validate_view_data(config)
      klass = klass_for_view_type[config[:type]]
      node = klass.new(view_data: config, parent: parent)
      create_tree(node, config[:views]) if config[:views] && config[:views].any?
      add_node_to_parent(node, parent) if parent
      node
    end

    def add_node_to_parent(node, parent)
      if parent.resource_for_identifier(node.identifier)
        raise Bcome::Exception::NodeIdentifiersMustBeUnique.new(node.namespace)
      else
        parent.resources << node
      end
    end
 
    def load_estate_config
      config = YAML.load_file(CONFIG_PATH).deep_symbolize_keys
      return config
    rescue
      raise Bcome::Exception::MissingEstateConfig, CONFIG_PATH
    end

    def validate_view_data(config)
      raise Bcome::Exception::InvalidEstateConfig, "Invalid view type for (#{config.inspect})" unless is_valid_view_type?(config[:type])
    end

    def klass_for_view_type
      {
        COLLECTION_KEY => ::Bcome::Node::Collection,
        INVENTORY_KEY => ::Bcome::Node::Inventory
      }
    end

    def is_valid_view_type?(view_type)
      klass_for_view_type.keys.include?(view_type)
    end
  end
end
