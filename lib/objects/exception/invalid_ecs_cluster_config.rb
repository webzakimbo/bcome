# frozen_string_literal: true

module Bcome
  module Exception
    class InvalidEcsClusterConfig < ::Bcome::Exception::Base
      def message_prefix
        'Invalid ecs cluster config'
       end
    end
  end
end
