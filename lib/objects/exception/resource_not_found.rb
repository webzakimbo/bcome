# frozen_string_literal: true

module Bcome
  module Exception
    class GcpResourceNotFound < ::Bcome::Exception::Base
      def message_prefix
        'Gcp resource not found'
      end
    end
  end
end
