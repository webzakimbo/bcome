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

    def prompt_breadcrumb
      "#{super}" + "\s(#{focus_breadcrumb.bc_orange})" 
    end

    def machines(skip_for_hidden = true)
      resources = skip_for_hidden ? @resources.active.reject(&:hide?) : @resources.active
      set = []
      resources.each do |resource|
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

    def do_set_resources(raw_resources)
      return [] if raw_resources.empty?

      if raw_resources.is_a?(Array)
        set_subselects_from_raw_data(raw_resources, parent.subdivide_namespaces_on_label)
        return
      end

      raw_resources.each do |resource_type, raw_resource|
        resource_klass = resource_klasses[resource_type]
        resource_klass = crd_resource_klass unless resource_klass

        raw_resource.each do |resource|
          add_resource(resource_klass, resource_type, resource)
        end
      end
      return
    end

    def set_subselects_from_raw_data(raw_resources, label_name)
      raw_data = raw_resources.is_a?(Array) ? raw_resources : raw_resources.values.flatten
      json_path = JsonPath.new("metadata.labels.#{label_name}")

      grouped_data = raw_data.group_by{|data| json_path.on(data) }

      # Could not group by, so return flat structure within namespace instead.
      return do_set_resources(raw_resources) if grouped_data.keys.flatten.empty?
      @is_subdivided = true

      grouped_data.each do |group_name, group_data|
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
      (super + %i[logs config reload]) - non_k8_menu_items
    end

    def menu_items
      base_items = super.dup

      base_items[:config] = {
        description: 'Display the k8 configuration for this node',
        group: :informational
      }

      base_items[:reload] = {
        description: 'Reload all resources',
        group: :informational
      }

      base_items[:logs] = {
        description: 'Live tail stdout (all selected pods)',
        group: :informational
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
      resources.active.each do |resource|
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
