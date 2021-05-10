# frozen_string_literal: true

module Bcome
  class Bootup
    def self.set_and_do(params, spawn_into_console = true)
      instance.set(params, spawn_into_console)
      instance.do
    end

    def self.traverse(breadcrumbs = nil, _spawn_into_console = false)
      spawn_into_console = false
      ::Bcome::Bootup.set_and_do({ breadcrumbs: breadcrumbs }, spawn_into_console)
    end

    def self.spider(breadcrumbs = nil)
      instance.spider({ breadcrumbs: breadcrumbs})
    end

    include Singleton

    attr_reader :breadcrumbs, :arguments

    def set(params, spawn_into_console = false)
      @breadcrumbs = params[:breadcrumbs]
      @arguments = params[:arguments]
      @spawn_into_console = spawn_into_console
    end

    def do
      context = crumbs.empty? ? init_context(estate) : traverse(estate)
      context
    end

    def init_context(context)
      context.load_nodes if context.respond_to?(:load_nodes) && !context.nodes_loaded?
 
      if @spawn_into_console
        ::Bcome::Workspace.instance.set(context: context, show_welcome: true)
      else
        context
      end
    end

    def spider(params)
      @breadcrumbs = params[:breadcrumbs]
      starting_context = estate

      crumbs.each_with_index do |crumb, _index|
        # Some contexts' resources are loaded dynamically and do not come from the estate config. As we're traversing, we'll need to load
        # them if necessary
        starting_context.load_nodes if starting_context.respond_to?(:load_nodes) && !starting_context.nodes_loaded?
        next_context ||= starting_context.resource_for_identifier(crumb)
        return unless next_context
        starting_context = next_context
      end
    end

    def traverse(_starting_context)
      starting_context = estate
      crumbs.each_with_index do |crumb, _index|
        # Some contexts' resources are loaded dynamically and do not come from the estate config. As we're traversing, we'll need to load
        # them if necessary
        starting_context.load_nodes if starting_context.respond_to?(:load_nodes) && !starting_context.nodes_loaded?

        # Attempt to load our next context resource
        next_context = starting_context.resources.active.first if crumb == 'first'
        next_context ||= starting_context.resource_for_identifier(crumb)

        # Our current breadcrumb is not a node, and so we'll attempt to invoke a method call on the previous
        # e.g. given resource:foo, then invoke 'foo' on 'resource'
        unless next_context
          puts "\n" # clean any trailing loading bars
          starting_context.invoke(crumb, @arguments)
          return
        end
        starting_context = next_context
      end

      # Set our workspace to our last context - we're not invoking a method call and so we're entering a console session
      init_context(starting_context)
    end

    def estate
      @estate ||= ::Bcome::Node::Factory.instance.init_tree
    end

    def estate_loaded?
      !@estate.nil?
    end

    def close_ssh_connections
      return unless estate_loaded?

      estate.close_ssh_connections
    end

    def parser
      ::Bcome::Parser::BreadCrumb.new(@breadcrumbs)
    end

    def crumbs
      parser.crumbs
    end

    private

    def teardown!
      @estate = nil
    end
  end
end
