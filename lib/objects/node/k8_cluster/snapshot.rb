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
      @namespaces = []
      @items = sort_resources
    end

    def loader_title
      "loading snapshot"
    end

    def loader_completed_title
      "done"
    end

    def sort_resources
      items = {}

      raw_items.pmap do |item|
        kind = item["kind"]
        if kind == "Namespace"
          @namespaces << item
          next
        end

        designated_namespace = item["metadata"]["namespace"]
        items[designated_namespace] = {} unless items[designated_namespace] 
        items[designated_namespace][kind] = items[designated_namespace][kind] ? items[designated_namespace][kind] << item : [item]
      end

      return items
    end

    def assign_resources_to_namespaces
      #wrap_indicator type: :progress, size: @namespaces.size, title: loader_title, completed_title: loader_completed_title do
         do_assign
      #end
    end

    def do_assign
      @namespaces.pmap do |data|
        # Create namespaces
        name = data["metadata"]["name"]
        namespace = @k8.gke_child_node_class.new(views: { identifier: name, raw_data: data }, parent: @k8)
        @k8.resources << namespace
 
        # Assign crds
        resources = @items[name] ? @items[name] : {}
        if @k8.respond_to?(:subdivide_namespaces_on_label)
          namespace.set_subselects_from_raw_data(resources, @k8.subdivide_namespaces_on_label)
        else 
          namespace.do_set_resources(resources)
        end

        ::Bcome::Node::Factory.instance.bucket[namespace.keyed_namespace] = namespace
        #signal_success
      end
    end

    private
   
    def get_command
      resource_names = ["pods"]
      parameters = "-o=custom-columns=NAME:.metadata.name,CONTAINERS:.spec.containers[*].name --all-namespaces"

      resource_names += default_resources
    
      return "get #{resource_names.join(",")} #{parameters}"
    end

    def default_resources
      ["namespaces"]
    end
 
    def get_config
      @config = @k8.run_kc(get_command)
      return @config
    end

    def raw_items
      @raw_items ||= @config["items"]
    end
  end
end
