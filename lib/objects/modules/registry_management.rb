# frozen_string_literal: true

module Bcome
  module Node
    module RegistryManagement
      def user_command_wrapper
        ::Bcome::Registry::CommandList.instance.group_for_node(self)
      end

      def registry
        command_group = user_command_wrapper
        if command_group&.has_commands?
          command_group.pretty_print
        else
          puts "\nYou have no registry commands configured for this namespace.".bc_white
          puts "\nSee the documentation at ".bc_white + "https://docs.bcome.com".informational + " if you need help.\n"
        end
      end
    end
  end
end
