module Bcome::Node::KubeHelper

  ## Abstracted loader for populating child nodes
  def set_child_nodes
    raw_nodes = run_kc(get_children_command)
    raw_nodes["items"].each do |item_data|
      config = {
        identifier: item_data["metadata"]["name"],
        raw_data: item_data
      }

      child_node = gke_child_node_class.new(views: config, parent: self)
      resources << gke_child_node_class.new(views: config, parent: self) 
      ::Bcome::Node::Factory.instance.bucket[child_node.keyed_namespace] = child_node  
    end
  end

  ## Shared utility methods
  def config
    ap(raw_config_data)
  end

  def k8_metadata
    @k8_metadata ||= raw_config_data["metadata"]
  end

  def k8_labels
    @k8_labels ||= k8_metadata["labels"]
  end

  def raw_config_data
    @views[:raw_data]
  end 

  def hyphenated_identifier
    # Kubernetes identifiers do not support underscores, but Bcome swaps all -'s to _'s in order to be able
    # to contantise identifier for traversing in the CLi.
    @original_identifier.gsub("_", "-")
  end

  ## Overrides
  def non_k8_menu_items
    %i[get put put_str rsync execute_script ping routes workon enable disable enable! disable!]
  end

end
