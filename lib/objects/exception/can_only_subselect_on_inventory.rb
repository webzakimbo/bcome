# frozen_string_literal: true

module Bcome
  module Exception
    class CanOnlySubselectOnInventory < ::Bcome::Exception::Base
      def message_prefix
        'Invalid subselect - can only subselect on another inventory'
      end
    end
  end
end
