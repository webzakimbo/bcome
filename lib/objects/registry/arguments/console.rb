# frozen_string_literal: true

module Bcome::Registry::Arguments
  class Console < Base
    def initialize(arguments, defaults)
      @arguments = arguments || {}
      super
    end

    private

    def validate
      raise Bcome::Exception::InvalidRegistryArgumentType, 'invalid argument format' unless @arguments.is_a?(Hash)

      super
    end
  end
end
