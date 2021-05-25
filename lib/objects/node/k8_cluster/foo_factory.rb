# Todo - benchmark get all with goal of dynamically grabbing all

module Bcome::Node::Collection
  class Snapshot < ::Bcome::Node::Collection::Base

    def initialize(k8)
      @k8 = k8
      @config = get_config
      sort_resources
      assign_resources_to_namespaces
    end

    def namespaces
      @namespaces ||= raw_items.select{|item| item["kind"] == "Namespace" }
    end 

    def sort_resources
      items = {}

      raw_items.each do |item|
        kind = item["kind"]
        next if kind == "Namespace"
    
        designated_namespace = item["metadata"]["namespace"]
        items[designated_namespace] = {} unless items[designated_namespace] 
        items[designated_namespace][kind] = items[designated_namespace][kind] ? items[designated_namespace][kind] << item : [item]
      end

      items
    end

    def assign_resources_to_namespaces
       namespaces.each do |namespace|
 
      end
    end

    private
 
    def get_config
      # TODO - benchmark setting this to *all*. Goal: dynamically grabbing all
      cmd = "get namespaces,pods,ingresses -o=custom-columns=NAME:.metadata.name,CONTAINERS:.spec.containers[*].name --all-namespaces"
      @config = @k8.run_kc(cmd)
    end

    def raw_items
      @raw_items ||= @config["items"]
    end

  end
end
