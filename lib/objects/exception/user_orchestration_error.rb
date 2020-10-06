# frozen_string_literal: true

module Bcome
  module Exception
    class UserOrchestrationError < ::Bcome::Exception::Base
      def message_prefix
        "Exception caught in orchestration script" 
      end
    end
  end
end
