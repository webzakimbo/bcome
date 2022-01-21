# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class VirtualService < Bcome::Node::K8Cluster::Child

    def gateways
      spec["gateways"]
    end

    def hosts
      spec["hosts"]
    end

    def http
      spec["http"]
    end

  end
end
