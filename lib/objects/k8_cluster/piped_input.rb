# frozen_string_literal: true

module Bcome
  class PipedInput

    include ThreadSafeSingleton

    attr_reader :command_suffix

    def pipe=(command_suffix)
      @command_suffix = "\s|#{command_suffix}"
    end
 
    def unset!
      @command_suffix = nil
    end

    def pipe?
      !@command_suffix.nil?
    end
  end
end
