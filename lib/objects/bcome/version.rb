# frozen_string_literal: true

module Bcome
  module Version
    def self.name
      'bcome'
    end

    def self.release
      '3.0.0'
    end

    def self.release_name
      'Maverick'
    end

    def self.display
      "#{name} v#{release} - #{release_name}"
    end
  end
end
