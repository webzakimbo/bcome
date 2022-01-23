# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Secret < Bcome::Node::K8Cluster::Child

    def readable
      as_human = {}
      data.each do |key, encoded_value|
        as_human[key] = ::Base64.decode64(encoded_value)
      end
      ap as_human, {indent: -2}
    end

    def enabled_menu_items
      (super + %i[readable]) 
    end

    def menu_items
      base_items = super.dup
 
      base_items[:readable] = {
        description: "Human readable secret outputs - base64 decoded",
        group: :contextual
      }
      base_items
    end

    def data
      raw_data["data"]
    end
  end
end
