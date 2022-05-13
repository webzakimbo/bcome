module Bcome::Node::KubeGenericMenuItems

  def enabled_menu_items
    (super + %i[describe config]) - non_k8_menu_items
  end

  def menu_items
    base_items = super.dup

     base_items[:describe] = {
      description: 'Describe this k8 node',
      group: :kubernetes
    }

    base_items[:config] = {
      description: 'Display the k8 configuration for this node',
      group: :kubernetes
    }
    base_items
  end

end
