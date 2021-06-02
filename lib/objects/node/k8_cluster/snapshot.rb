# TODO - set one type of object as FOCUSED and allow FOCUS on any other
#  ~ maybe we can focus on more that one at a time?  This would play havoc with log, run etc from namespace level 
#  Perhaps on a snapshot reload, menu changes dynamically as to what is in focus?
# TODO - deployment accessor on POD ?!

module Bcome::Node::Collection
  class Snapshot < ::Bcome::Node::Collection::Base

    class << self
      def do(k8)
        snapshot = new(k8)
        snapshot.assign_resources_to_namespaces
      end
    end

    include ::Bcome::LoadingBar::Handler 

    def initialize(k8)
      @k8 = k8
      @config = get_config
      @items = sort_resources
    end

    ## Loading
    def loader_title
      "k8/snaphotting namespaces" 
    end

    def loader_completed_title
      "done"
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
      wrap_indicator type: :progress, size: @items.keys.size, title: loader_title, completed_title: loader_completed_title do
        do_assign
      end
    end

    def do_assign
      @items.each do |namespace_identifier, resources|
        namespace_data = raw_items.select{|item| item["kind"] == "Namespace" }

        namespace = @k8.gke_child_node_class.new(views: { identifier: namespace_identifier, raw_data: namespace_data }, parent: @k8)
        @k8.resources << namespace

        if @k8.respond_to?(:subdivide_namespaces_on_label)
          namespace.set_subselects_from_raw_data(resources, @k8.subdivide_namespaces_on_label)
        else 
          namespace.set_resources(resources)
        end

        ::Bcome::Node::Factory.instance.bucket[namespace.keyed_namespace] = namespace
        signal_success
      end 
    end

    private
 
    def get_config
      cmd = "get namespaces,pods,ingresses,services -o=custom-columns=NAME:.metadata.name,CONTAINERS:.spec.containers[*].name --all-namespaces"
      #cmd = "get all -o=custom-columns=NAME:.metadata.name,CONTAINERS:.spec.containers[*].name --all-namespaces"
      @config = @k8.run_kc(cmd)
    end

    def raw_items
      @raw_items ||= @config["items"]
    end

  end
end
