# frozen_string_literal: true

module Bcome
  module Tree

    include Bcome::Draw

    ####################################################################
    ## Node tree  - dynamic rendering of any parent->*child hierarchy  #
    ####################################################################
    def tree(config = {})
      unless resources.any?
        puts "No tree available at this node. #{type.capitalize.informational} #{identifier.bc_white} does not have any children.\n\n"
        return 
      end

      config = {} unless config.is_a?(Hash)
      title_prefix = 'Namespace tree'
        iterate_over = config[:callers] ? config[:callers] : resources.active
        iterate_over.pmap do |resource|
          if resource.respond_to?(:load_nodes) && !resource.nodes_loaded?
            resource.load_nodes
          end  
        end
        return build_tree(:network_namespace_tree_data, title_prefix, config)
      #end
    end

    ######################
    ## SSH Routing tree ##
    ######################
    def routes
      if machines.nil? ||  machines.empty?
        puts "\nNo routes are found below this namespace (empty server list)\n".warning
      else
        title_prefix = 'Ssh connection routes'
        build_tree(:routing_tree_data, title_prefix, {})
      end
    end

    def routing_tree_data(caller_stack)
      @tree = {}

      # For each namespace, we have many proxy chains
      proxy_chain_link.link.each do |proxy_chain, machines|
        is_direct = proxy_chain.hops.any? ? false : true

        if inventory?
          load_nodes unless nodes_loaded?
        end

        ## Machine data
        machine_data = {}
        machines.each do |machine|
          key = machine.routing_tree_line(is_direct)
          machine_data[key] = nil
        end

        ## Construct Hop data
        hops = proxy_chain.hops
        hop_lines = hops.compact.enum_for(:each_with_index).collect { |hop, index| hop.pretty_proxy_details(index + 1) }

        @tree.merge!(to_nested_hash(hop_lines, machine_data))
      end

      @tree
    end

    def to_nested_hash(array, data)
      nested = array.reverse.inject(data) { |a, n| { n => a } }
      nested.is_a?(String) ? { "#{nested}": nil } : nested
    end

    def network_namespace_tree_data(caller_stack = nil)
      @tree = {}

      if (caller_stack && (element = caller_stack.shift))
        iterate_over = [element]
        geneaology = caller_stack.empty? ? :descendent : :ancestor
      else
        iterate_over = resources.active
        geneaology = :descendent
      end 

      iterate_over.sort_by(&:identifier).each do |resource|
        next if resource.hide?
        resource.load_nodes if resource.respond_to?(:load_nodes) && !resource.nodes_loaded?

        unless resource.is_a?(Bcome::Node::Inventory::Merge)
          next if resource.parent && !resource.parent.resources.is_active_resource?(resource)
        end

        @tree[resource.namespace_tree_line(geneaology)] = resource.resources.any? ? resource.network_namespace_tree_data(caller_stack) : nil
      end

      @tree
    end

    def namespace_tree_line(geneaology)
      colour = geneaology == :ancestor ? :bc_grey : :bc_green
      "#{type.send(colour)} #{tree_identifier}"
    end

    def routing_tree_line(is_direct = true)
      address = if is_direct && public_ip_address
                  public_ip_address
                else
                  internal_ip_address
                end

      [
        type.to_s.bc_cyan,
        "namespace:\s".bc_green + keyed_namespace,
        "ip address\s".bc_green + address.to_s,
        "user\s".bc_green + ssh_driver.user
      ]
    end

    def build_tree(data_build_method, title_prefix, config)
      caller_stack = config[:callers] ? config[:callers].reverse : []

      depth = config[:depth]
      depth = depth.to_i + caller_stack.size  if depth 
      data = send(data_build_method, caller_stack)

      @lines = []
      title = "#{title_prefix.informational}\s#{namespace.resource_key}"
      @lines << "\n"
      @lines << "#{BLIP}\s\s\s#{title}"
      @lines << INGRESS.to_s

      if data.nil?
        parent.build_tree(data_build_method)
        return
      end
   
      padding = ""

      recurse_tree_lines(data, padding, depth)

      @lines.each do |line|
        print "#{LEFT_PADDING}#{line}\n"
      end

      print "\n\n"
      p
    end

    def recurse_tree_lines(data, padding, depth)
      depth -= 1 if depth && depth > 0

      data.each_with_index do |config, index|
        key = config[0]
        values = config[1]

        anchor, branch = deduce_tree_structure(index, data.size)
        labels = key.is_a?(Array) ? key : [key]
 
        labels.each_with_index do |label, index|
          key_string = if index == 0 #  First line
                         "#{anchor}\s#{label}"
                       else # Any subsequent line
                         "#{branch}#{"\s" * 4}\s#{label}"
                       end

          entry_string = "#{padding}#{key_string}"
          @lines << entry_string
        end # End labels group

        @lines << "#{padding}#{branch}" if labels.size > 1
        next unless values&.is_a?(Hash)

        tab_padding = padding + branch + ("\s" * (anchor.length + 4))

        if depth.nil? || (depth && depth > 0)
          recurse_tree_lines(values, tab_padding, depth)
          @lines << padding + branch
        end
      end
      nil
    end

    def deduce_tree_structure(index, number_lines)
      return BOTTOM_ANCHOR, "\s" if (index + 1) == number_lines

      [MID_SHIPS, BRANCH]
    end
  end
end
