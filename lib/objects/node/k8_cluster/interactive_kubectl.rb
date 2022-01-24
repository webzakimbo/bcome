module Bcome
  module InteractiveKubectl

    def kubectl(command = nil)
      ::Bcome::Interactive::Session.run(self, :interactive_kubectl, { command: command })
    end

  end
end
