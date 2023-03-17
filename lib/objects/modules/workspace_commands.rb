# frozen_string_literal: true
module Bcome
  module WorkspaceCommands

    def ssh_connect(params = {})
      ::Bcome::Ssh::Connector.connect(self, params)
    end

    def lsr
      reload if respond_to?(:reload)
      ls
    end

    def ls(node = self, active_only = false)
      if node != self && (resource = resources.for_identifier(node))
        resource.send(:ls, active_only)
      else
        
        puts "\n\n\tYou are in\s".bc_white + "#{type}".informational + "\s#{identifier}\n".bc_white

        iterate_over = active_only ? resources.active : resources

        puts "\t" + "children\n".bc_white.underline if iterate_over.any?

        if iterate_over.any?
          iterate_over.sort_by(&:identifier).each do |resource|
            next if resource.hide?
            is_active = resources.is_active_resource?(resource)
            puts resource.pretty_description(is_active) 
            puts "\n"
          end
        else
          puts "\tNo child resources".informational
        end

        new_line
        nil
      end
    end

    def pretty_child_type
      return resources.first.type.pluralize(resources.size)
    end

    def lsa
      show_active_only = true
      ls(self, show_active_only)
    end

    def ping(node = nil)
      ping_params = { is_ping: true, show_progress: true }
      ::Bcome::Ssh::Connector.connect(node ? node : self, ping_params)   
    end

    def parents
      ps = []
      ps << [parent, parent.parents] if has_parent?
      ps.flatten
    end

    def cd(breadcrumb)
      crumbs = breadcrumb.split(":")

      if breadcrumb =~ /#(.+)/ # cd from root of namespace where '#' denotes 'root'
        root.send(:cd, $1)
      else # cd into a child namespace
        crumbs = breadcrumb.split(":")   
        step = self

        crumbs.each do |crumb|
          step.load_nodes if step.respond_to?(:load_nodes) && !step.nodes_loaded?

          if step = step.resources.for_identifier(crumb)
            unless step.parent.resources.is_active_resource?(step)
              puts "\nCannot enter context - #{breadcrumb} is disabled\n".error
              return
            end
          else
            raise Bcome::Exception::InvalidBreadcrumb, "Cannot find a node at '#{crumb}'"
          end
       end
        ::Bcome::Workspace.instance.set(current_context: self, context: step)
      end
    end

    def run(*raw_commands) 
      raise Bcome::Exception::MethodInvocationRequiresParameter, "Please specify commands when invoking 'run'" if raw_commands.empty?

      results = {}

      ssh_connect(show_progress: true)

      machines.pmap do |machine|
        commands = machine.do_run(raw_commands)
        results[machine.namespace] = commands
      end
      results
    end

    def pretty_description(is_active = true)
      desc = ''

      iteratable_attrs = @additional_list_attributes ? (list_attributes.merge(@additional_list_attributes)) : list_attributes

      @key_spacing_limit = iteratable_attrs.keys.max_by(&:length).size + 2
      iteratable_attrs.each do |key, value|

        next unless respond_to?(value) || instance_variable_defined?("@#{value}")

        attribute_value = send(value).to_s
        next if attribute_value.nil? || attribute_value.empty?

        printed_value = (value.to_sym == :identifier) ? "#{"id".resource_key}:\s#{attribute_value}" : attribute_value

        desc += "\t"
        desc += is_active ? key.to_s.resource_key : key.to_s.resource_key_inactive

        if key.length >= @key_spacing_limit 
          desc += "\s"
        else    
          desc += "\s" * (@key_spacing_limit - key.length)
        end


        desc += is_active ? printed_value.resource_value : printed_value.resource_value_inactive
        desc += "\n"
        desc = desc unless is_active
      end
      desc
    end

    def disable(*ids)
      ids.each { |id| resources.do_disable([id]) }
      puts "Disabled #{ids.join(', ')} from selection.".informational 
    end

    def enable(*ids)
      resources.do_enable(ids, reset = false)
      puts "Enabled #{ids.join(', ')} in selection.".informational
    end

    def clear!
      # Clear any disabled selection at this level and at all levels below
      resources.clear!
      resources.each(&:clear!)
      nil
    end

    def workon(*ids)
      resources.do_enable(ids)
      puts "\nYou are now working on '#{ids.join(', ')}\n".informational
    end

    def disable!
      resources.disable!
      resources.each(&:disable!)
      return
    end

    def enable!
      resources.enable!
      resources.each(&:enable!)
      return
    end

    ## Helpers --

    def resource_identifiers
      resources.collect(&:identifier)
    end

    def is_node_level_method?(method_sym)
      respond_to?(method_sym) || method_is_available_on_node?(method_sym)
    end

    def method_in_registry?(method_sym)
      ::Bcome::Registry::CommandList.instance.command_in_list?(self, method_sym)
    end

    def method_is_available_on_node?(method_sym)
      begin
        resource_identifiers.include?(method_sym.to_s) || method_in_registry?(method_sym) || respond_to?(method_sym) || instance_variable_defined?("@#{method_sym}")
      rescue NameError
        return false
      end
    end

    def tree_descriptions
      pretty_desc = "#{description} (#{type})"
      d = parent ? parent.tree_descriptions + [pretty_desc] : [pretty_desc]
      d.flatten
    end

    def new_line
      puts "\n"
    end
  end
end
