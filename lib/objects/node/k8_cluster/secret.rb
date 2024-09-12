# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Secret < Bcome::Node::K8Cluster::Child

    def read
      as_human = {}
      print "\n"
      data.each do |key, encoded_value|
        puts "#{key.informational}: #{::Base64.decode64(encoded_value)}"
        puts ""
      end
      return 
    end

    def enabled_menu_items
      (super + %i[read]) 
    end

    def menu_items
      base_items = super.dup
 
      base_items[:read] = {
        description: "Human readable secret outputs - base64 decoded",
        group: :kubernetes
      }
      base_items
    end

    def data
      raw_data["data"]
    end
  end
end
