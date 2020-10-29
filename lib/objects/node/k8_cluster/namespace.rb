# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Namespace < Bcome::Node::Base

    # TODO - make raw config accessible

    def initialize(params)
      super
    end

    def type
      'k8 namespace'
    end

  end
end
