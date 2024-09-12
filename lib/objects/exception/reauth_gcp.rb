# frozen_string_literal: true

module Bcome
  module Exception
    class ReauthGcp < ::Bcome::Exception::Base
      def message_prefix
        'GCP session needs to be reauthenticated'
      end
    end
  end
end
