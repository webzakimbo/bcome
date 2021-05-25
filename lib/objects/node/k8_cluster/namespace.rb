# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Namespace < Bcome::Node::K8Cluster::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeListHelper
    include ::Bcome::Node::KubeCommandHelper
    include ::Bcome::Node::K8Cluster::HelmWrap
    include ::Bcome::InteractiveHelm
    
    def initialize(params)
      super
      @nodes_loaded = false
    end

    def machines(skip_for_hidden = true)
      resources = skip_for_hidden ? @resources.active.reject(&:hide?) : @resources.active
      set = []
      resources.each do |resource|
        set << resource.machines(skip_for_hidden)
      end

      return set.flatten!
    end

    def set_subselects_from_raw_data(raw_pods_data, label_name)  
      @raw_pods_data = raw_pods_data
      json_path = JsonPath.new("metadata.labels.#{label_name}")

      grouped_pod_data = raw_pods_data.group_by{|data| json_path.on(data) }
    
      # Could not group by, so return flat structure within namespace instead.
      return set_pods_from_raw_data(raw_pods_data) if grouped_pod_data.keys.flatten.empty?

      grouped_pod_data.each do |group_name, group_data|
        views = {
          identifier: group_name.first.nil? ? "ungrouped" : group_name.first,
          subselect_parent: self
        }

        subselect = ::Bcome::Node::K8Cluster::GroupedSubselectK8.new(views: views, pods_data: group_data, parent: self, grouped_by_label: label_name) 
        resources << subselect
        ::Bcome::Node::Factory.instance.bucket[subselect.keyed_namespace] = subselect
      end
      return
    end
    def gke_child_node_class
      ::Bcome::Node::K8Cluster::Pod
    end

    def k8_namespace
      self
    end

    def set_pods_from_raw_data(raw_pods_data)
      raw_pods_data.pmap do |pod_data|
        pod_identifier = pod_data["metadata"]["name"]

        namespace_config = {
          identifier: pod_identifier,
          raw_data: pod_data
        }
        pod = gke_child_node_class.new(views: namespace_config, parent: self)
        resources << pod
        pod.set_containers
        ::Bcome::Node::Factory.instance.bucket[pod.keyed_namespace] = pod
      end
      return
    end

    def crds
      @crds ||= {}
    end

    def set_resources(raw_resources)
      raw_resources.each do |resource_type, raw_resource|
        resource_klass = resource_klasses[resource_type]
        resource_klass = crd_resource_klass unless resource_klass 

        raw_resource.each do |raw_resource|
          resource = resource_klass.new(views: {identifier: raw_resource["metadata"]["name"], raw_data: raw_resource}, parent: self)

          if resource_klass == ::Bcome::Node::K8Cluster::Pod  ## Focus on       
            resources << resource 
            resource.set_containers
          else
            crds[resource_type] = crds[resource_type] ? (crds[resource_type] << resource) : [resource]
          end
         
          ::Bcome::Node::Factory.instance.bucket[resource.keyed_namespace] = resource
        end
      end

      return
    end

    def resource_klasses
      {
        "Pod" => ::Bcome::Node::K8Cluster::Pod
      }
    end
  
    def crd_resource_klass
      ::Bcome::Node::K8Cluster::Crd
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
      run_kc("get ingresses")
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
