# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Namespace < Bcome::Node::Base

    def initialize(params)
      @view_config = params[:views]
      @identifier = @view_config[:identifier].dup
      @description = @view_config[:description]
      super
    end

    def type
      'k8 namespace'
    end

  end
end
