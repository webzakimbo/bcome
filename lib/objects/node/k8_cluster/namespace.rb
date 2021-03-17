# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Namespace < Bcome::Node::K8Cluster::Base

    include ::Bcome::Node::KubeHelper
    include ::Bcome::Node::KubeListHelper
    include ::Bcome::Node::KubeCommandHelper
    
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

    def set_subselects_from_raw_data(raw_pods_data, path)  
      json_path = JsonPath.new(path)

      grouped_pod_data = raw_pods_data.group_by{|data| json_path.on(data) }
      grouped_pod_data.each do |group_name, group_data|
        views = {
          identifier: group_name.first,
          subselect_parent: self
        }

        subselect = ::Bcome::Node::K8Cluster::GroupedSubselectK8.new(views: views, pods_data: group_data, parent: self) 
        resources << subselect
        ::Bcome::Node::Factory.instance.bucket[subselect.keyed_namespace] = subselect
      end
      return
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

    def gke_child_node_class
      ::Bcome::Node::K8Cluster::Pod
    end

    def k8_cluster
      parent.k8_cluster
    end

  end
end
