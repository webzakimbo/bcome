# frozen_string_literal: true

module Bcome
  module Exception
    class EmptyNamespaceTree < ::Bcome::Exception::Base
      def message_prefix
        'Empty namespace tree'
      end
    end
  end
end
