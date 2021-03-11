module Bcome
  module InteractiveKubectl

    def kubectl
      ::Bcome::Interactive::Session.run(self, :interactive_kubectl)
    end

  end
end
