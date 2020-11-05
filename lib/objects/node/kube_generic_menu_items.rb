module Bcome::Node::KubeGenericMenuItems

  def enabled_menu_items
    (super + %i[config]) - non_k8_menu_items
  end

  def menu_items
    base_items = super.dup
    base_items[:config] = {
      description: 'Display the k8 configuration for this node',
      group: :informational
    }
    base_items
  end

end
