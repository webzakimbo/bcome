module Bcome::Node::KubeHelper

  ## Abstracted loader for populating child nodes
  def set_child_nodes
    raw_nodes = run_kc(get_children_command)
    raw_nodes["items"].each do |item_data|
      config = {
        identifier: item_data["metadata"]["name"],
        description: gk3_child_node_description,
        raw_data: item_data
      }
      resources << gke_child_node_class.new(views: config, parent: self)
    end
  end

  ## Shared utility methods
  def config
    colour = "purpleish" ; 
    ap(raw_config_data, indent: -3, color:  { hash: colour, symbol: colour, string: colour, keyword: colour, variable: colour, array: colour })
  end

  def raw_config_data
    @views[:raw_data]
  end 

  def hyphenated_identifier
    # Kubernetes identifiers do not support underscores, but Bcome swaps all -'s to _'s in order to be able
    # to contantise identifier for traversing in the CLi.
    identifier.gsub("_", "-")
  end

end
