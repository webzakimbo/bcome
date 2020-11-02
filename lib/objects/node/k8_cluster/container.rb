# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Container < Bcome::Node::Base

    include ::Bcome::Node::KubeHelper

    def machines
      [self]
    end
  
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

    ## Get a shell onto the container
    def shell
      exec("/bin/bash")
    end

    ## Execute an arbitrary command
    def run(args)
      command = "#{exec_preamble} sh -c '#{args}'"
      run_kubectl_cmd(command)
    end
 
    def exec(args)
      command = "#{exec_preamble} #{args}"
      run_kubectl_cmd(command)     
    end

    def exec_preamble
      "exec -it -n #{k8_namespace.hyphenated_identifier} #{parent.hyphenated_identifier} - container #{hyphenated_identifier} --"
    end

    def run_kubectl_cmd(command)
      k8_cluster.run_kubectl_cmd(command)
    end

    def k8_cluster
      parent.k8_cluster
    end 

  end
end
