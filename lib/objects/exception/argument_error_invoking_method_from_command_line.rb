# frozen_string_literal: true

module Bcome
  module Exception
    class ArgumentErrorInvokingMethodFromCommmandLine < ::Bcome::Exception::Base
      def message_prefix
        'Argument error invoking method. Please refer to documentation for invoking this command from the command line: '
      end
    end
  end
end
