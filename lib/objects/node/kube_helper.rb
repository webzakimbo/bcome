module Bcome::Node::KubeHelper

  def matches_filter?(filter)
    k8_path_filter = ::Bcome::Node::Resources::K8PathFilter.new(self, filter)
    return k8_path_filter.match?
  end

  def matches_filters?(filters)
    # get result of all matches
    all_matches = filters.collect{|filter| matches_filter?(filter) }

    # test we don't have any false results
    !(all_matches.select{|result| !result }.size > 0)
  end

  ## Shared utility methods
  def config  
    puts raw_config_data.to_yaml
  end

  def describe
    return unless is_describable?
    describe_cmd = "describe #{self.type} #{self.identifier}"
    print parent.run_kubectl_cmd(describe_cmd).data.stdout
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
    # to constantise identifier for traversing in the CLi.
    @original_identifier.gsub("_", "-")
  end

  ## Overrides
  def non_k8_menu_items
    %i[ssh get put put_str rsync execute_script ping routes workon enable disable enable! disable!]
  end

  ## Disable non container methods - revisit this as clear arch. issue with menu structure
  def ping  
  end

  def put(*params)
  end

  def put_str(*params)
  end

  def rsync(*params)
  end

  def execute_script(*params)
  end

end
