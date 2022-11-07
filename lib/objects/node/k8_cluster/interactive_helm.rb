module Bcome
  module InteractiveHelm

    def helm(command = nil)
      if command
        run_helm(command)
       else
        ::Bcome::Interactive::Session.run(self, :interactive_helm)
      end
    end

  end
end
