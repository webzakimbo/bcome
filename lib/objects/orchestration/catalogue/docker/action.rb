module Bcome::Orchestration::Catalogue
  module Docker
      module Action

        def list
          @container_info = []
          get_raw_containers_info
          puts "\n\n"
          pretty_container_info
        end

        def reset_filter
          @filter = nil
          list
        end

        def back_to_default
          @selection = :default
        end

      end
    end
end
