# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Namespace < Bcome::Node::K8Cluster::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeListHelper
    include ::Bcome::Node::KubeCommandHelper
    include ::Bcome::Node::K8Cluster::HelmWrap
    include ::Bcome::Node::K8Cluster::ResourceMappings
    include ::Bcome::InteractiveHelm
    include ::Bcome::Node::K8Cluster::PathwayRender
       
    attr_reader :is_subdivided

    def initialize(params)
      super
      @nodes_loaded = false
      @is_subdivided = false
    end

    def prompt_breadcrumb(config = {})
      return super unless config[:focus] && focus_breadcrumb
      return "#{super}" + "\s(#{focus_breadcrumb.pluralize})" 
    end

    def machines(skip_for_hidden = true)
      return [] unless @resources
      resources = skip_for_hidden ? @resources.active.reject(&:hide?) : @resources.active
      set = []
      resources.pmap do |resource|
        set << resource.machines(skip_for_hidden)
      end

      return set.flatten!
    end

    def gke_child_node_class
      ::Bcome::Node::K8Cluster::Pod
    end

    def k8_namespace
      self
    end

    def export_context
      parent.export_context(self)
    end

    def do_set_resources(raw_resources)
      return [] if raw_resources.empty?

      ## 1. UNSORTED --
      if raw_resources.is_a?(Array)
        ## GROUP BY -
        if parent.respond_to?(:subdivide_namespaces_on_label)
          set_subselects_from_raw_data(raw_resources, parent.subdivide_namespaces_on_label)
          return
        else
          ## UNGROUPED --
          raw_resources.pmap do |resource|
            resource_type = resource["kind"]
            resource_klass = resource_klasses[resource_type]
            resource_klass = crd_resource_klass unless resource_klass
            add_resource(resource_klass, resource_type, resource)
          end
          return
        end
      end

      ## 2. SORTED --
      raw_resources.pmap do |resource_type, raw_resource|
        resource_klass = resource_klasses[resource_type]
        resource_klass = crd_resource_klass unless resource_klass

        next if raw_resource.nil?
        raw_resource.pmap do |resource|
          add_resource(resource_klass, resource_type, resource)
        end
      end
      return
    end

    def set_subselects_from_raw_data(raw_resources, label_name)
      raw_data = raw_resources.is_a?(Array) ? raw_resources : raw_resources.values.flatten
      json_path = JsonPath.new("metadata.labels.#{label_name}")

      grouped_data = raw_data.group_by{|data| json_path.on(data) }
      grouped_data = { [] => raw_data } if grouped_data.keys.flatten.empty? # hack: if cannot group by, pretend...

      @is_subdivided = true

      grouped_data.pmap do |group_name, group_data|
        views = {
          identifier: group_name.first.nil? ? "ungrouped" : group_name.first,
          subselect_parent: self
        }

        subselect = ::Bcome::Node::K8Cluster::GroupedSubselectK8.new(views: views, data: group_data, parent: self, grouped_by_label: label_name)

        resources << subselect
        ::Bcome::Node::Factory.instance.bucket[subselect.keyed_namespace] = subselect
      end

      return
    end

    def enabled_menu_items
      (super + %i[export_context lsr describe focus pathways logs config reload kubectl helm]) - non_k8_menu_items
    end

    def menu_items
      base_items = super.dup

      base_items[:lsr] = {
        description: 'Reload from remote & list',
        group: :informational
      }

      base_items[:reload] = {
        description: 'Reload all resources',
        group: :informational
      }

       base_items[:describe] = {
        description: 'Describe this k8 node',
        group: :kubernetes
      }

      base_items[:config] = {
        description: 'Display the k8 configuration for this node',
        group: :kubernetes
      }

      base_items[:interactive] = {
        description: 'Execute commands against all containers in this namespace',
        group: :ssh,
      }

      base_items[:export_context] = {
        description: "Export this cluster namespace's kubectl context - i.e. set this context for external applications",
        group: :kubernetes
      }

      base_items[:focus] = {
        description: "Switch workspace to focus on a specific kubernetes resource",
        group: :kubernetes,
        usage: "focus resource_name, e.g. focus secrets",
        console_only: true
      }

      base_items
    end

    def logs(cmd = "")
      resources.active.pmap do |pod|
        pod.logs(cmd)
      end
    end

    def reload
      do_reload
      # We now have an alternative counterpart - reloaded from fresh, a different object.
      other = ::Bcome::Orchestrator.instance.get(keyed_namespace)
      ::Bcome::Workspace.instance.set(current_context: other, context: other)
    end

    def do_reload
      parent.reload
    end

    def nodes_loaded?
      true 
    end  

    def log
      resources.active.pmap do |resource|
        puts "#{resource.keyed_namespace}".bc_cyan + " / log" 
        resource.log
      end  
    end

    def requires_description?
      false
    end

    def type
      "namespace"
    end

    def ingresses
      if parent.respond_to?(:subdivide_namespaces_on_label)
        resources.active.collect{|resource| resource.crds["Ingress"] }.flatten.compact
      else
        crds["Ingress"]
      end
    end  

    def delegated_kubectl_cmd(command)
      command_in_context = append_namespace_to(command)
      parent.delegated_kubectl_cmd(command_in_context)
    end

    def run_kubectl_cmd(command)
      command_in_context = append_namespace_to(command)
      parent.run_kubectl_cmd(command_in_context)
    end

    def run_kc(command)
      command_in_context = append_namespace_to(command)
      parent.k8_cluster.run_kubectl(command_in_context)
    end

    def append_namespace_to(command)
      "#{command} -n #{hyphenated_identifier}"
    end 

    def get_children_command
      "get pods"
    end

    def k8_cluster
      parent.k8_cluster
    end
  end
end
