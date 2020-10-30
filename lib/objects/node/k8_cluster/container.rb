# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Container < Bcome::Node::Base

    include ::Bcome::Node::KubeHelper

    def type
      "container"
    end

    def run_kc(command)
      command_in_context = "#{command}\s#{hyphenated_identifier}"
      parent.run_kc(command_in_context)
    end

    def k8_namespace
      parent.k8_namespace
    end 

    def shell
      exec("/bin/sh")
    end

    def exec(args)
      command = "exec -it -n #{k8_namespace.hyphenated_identifier} #{parent.hyphenated_identifier} - container #{hyphenated_identifier} -- #{args}"
      run_kubectl_cmd(command)     
    end

    def run_kubectl_cmd(command)
      k8_cluster.run_kubectl_cmd(command)
    end

    def k8_cluster
      parent.k8_cluster
    end 

  end
end
