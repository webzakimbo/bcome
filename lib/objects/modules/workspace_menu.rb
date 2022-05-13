# frozen_string_literal: true

module Bcome
  module WorkspaceMenu
    def menu
      print "\n\n"
      puts "Command Menu".bc_yellow.bold + "\s\s#{description}"
  
      grouped_menu_items = menu_items.group_by { |m| m[1][:group] }

      grouped_menu_items.each do |group_key, items|
        # If we're not in a console session, we filter out console only methods
        items = items.reject { |item| item[1][:console_only] } unless ::Bcome::System::Local.instance.in_console_session?

        # reject disabled menu items
        items = items.reject { |item| !enabled_menu_items.include?(item[0]) }

        next if items.empty?

        s_heading = "/ #{menu_group_names[group_key]}"
        print "\n\n" + tab_spacing + s_heading.upcase.bc_cyan
        print item_spacing(s_heading) + ("\s" * 110).to_s.bc_cyan.underline
        print "\n\n"
        print_menu_items(items)
      end

      nil
    end

    # TODO model menu items...
    def print_menu_items(items)
      items.each_with_index do |item, _index|
        key = item[0]
        config = item[1]

        next if !::Bcome::System::Local.instance.in_console_session? && config[:console_only]

        puts tab_spacing + key.to_s.resource_key + item_spacing(key) + (config[:description]).to_s.resource_value

        if config[:usage] && ::Bcome::System::Local.instance.in_console_session?
          puts tab_spacing + ("\s" * menu_item_spacing_length) + 'usage: '.instructional + config[:usage]   
        elsif config[:terminal_usage] && !::Bcome::System::Local.instance.in_console_session?
          usage_string = "bcome #{keyed_namespace.empty? ? '' : "#{keyed_namespace}:"}#{config[:terminal_usage]}"
          puts tab_spacing + ("\s" * menu_item_spacing_length) + 'usage: '.instructional + usage_string
        end 

        if config[:application] && config[:application] == :vm_only
          puts tab_spacing + ("\s" * menu_item_spacing_length) + "note:\s".warning + "VMs only - no container support"
        end

        puts "\n"
      end
    end

    def mode
      ::Bcome::System::Local.instance.in_console_session? ? 'Console' : 'Terminal'
    end

    def item_spacing(item)
      "\s" * (menu_item_spacing_length - item.length)
    end

    def menu_item_spacing_length
      16
    end

    def tab_spacing
      "\s" * 3
    end

    def menu_group_names
      {
        ssh: 'Command Exec',
        informational: 'Informational',
        selection: 'Selections',
        file: 'File & Script',
        navigation: 'Navigational',
        miscellany: 'Miscellaneous',
        command_list: 'Command lists',
        kubernetes: 'Kubernetes',
        contextual: 'Contextual'
      }
    end

    def menu_items
      {
        routes: {
          description: 'Print SSH routing tree',
          console_only: false,
          group: :informational
        },
        ls: {
          description: 'list all available namespaces',
          console_only: false,
          group: :informational
        },
        lsa: {
          description: 'list all active namespaces',
          console_only: true,
          group: :informational
        },
        workon: {
          description: 'work on specific namespaces only, inactivating all others from this selection',
          usage: 'workon identifier1, identifier2 ...',
          console_only: true,
          group: :selection
        },
        disable: {
          description: 'remove a namespace from this selection',
          usage: 'disable identifier1, identifier2 ...',
          console_only: true,
          group: :selection
        },
        enable: {
          description: 're-enable a namespace within this selection',
          usage: 'enable identifier1, identifier2 ...',
          console_only: true,
          group: :selection
        },
        enable!: {
          description: 'enable all namespaces within this selection',
          console_only: true,
          group: :selection
        },
        disable!: {
          description: 'disable all namespaces within this selection',
          console_only: true,
          group: :selection
        },
        run: {
          description: "execute a command to be run against every server/container in all active namepaces",
          usage: "run 'command1', 'command2', ...",
          console_only: false,
          terminal_usage: "run 'command1' 'command2' ...",
          group: :ssh
        },
        interactive: {
          description: 'execute commands against every server/container in all active namepaces',
          console_only: false,
          group: :ssh
        },
        tree: {
          description: 'print a tree view of your elements',
          usage: "tree OR tree(depth: integer)",  
          console_only: false,
          group: :informational
        },
        ping: {
          description: 'ping all virtual machines to test connectivity',
          application: :vm_only,
          console_only: false,
          group: :ssh
        },
        put: {
          description: 'upload a file or directory using scp',
          application: :vm_only,
          usage: "put 'local/path','remote/path'",
          console_only: false,
          terminal_usage: "put 'local/path' 'remote/path'",
          group: :file
        },
        put_str: {
          description: 'Write a file /to/remote/path from a string',
          application: :vm_only,
          usage: 'put_str "string" "remote/path"',
          console_only: false,
          terminal_usage: "put_str '<file contents>', 'remote/path'",
          group: :file
        },
        rsync: {
          description: 'upload a file or directory using rsync (faster)',
          application: :vm_only,
          usage: "rsync 'local/path','remote/path'",
          console_only: false,
          terminal_usage: "rsync 'local/path' 'remote/path'",
          group: :file
        },
        cd: {
          description: 'navigate to any other namespace',
          usage: 'For child namespaces: cd identifier OR cd foo:bar. For any namespace: cd #root:foo:bar',
          console_only: true,
          group: :navigation
        },
        quit: {
          description: 'Quit out of bcome',
          console_only: true,
          group: :navigation
        },
        back: {
          description: 'Go back up a namespace',
          console_only: true,
          group: :navigation
        },
        meta: {
          description: 'Print out all metadata related to this node',
          group: :informational
        },
        registry: {
          description: 'List all user defined commands present in your registry, and available to this namespace',
          console_only: false,
          group: :command_list
        },
        menu: {
          description: 'List all available commands',
          console_only: false,
          group: :command_list
        },
        execute_script: {
          description: 'execute a bash script',
          console_only: false,
          usage: 'execute_script "script_name"',
          terminal_usage: 'execute_script script_name',
          group: :ssh
        },
        logs: {
          description: 'Live stream all container logs in selection',
          group: :kubernetes
        },
        pathways: {
          description: 'Map the paths to your containers via their ingresses and services',
          group: :kubernetes
        },
        helm: {
          description: "Access an interactive helm shell, scoped to this node's kubectl context",
          group: :kubernetes
        },
        kubectl: {
          description: "Access an interactive kubectl shell, scoped to this node's kubectl context",
          group: :kubernetes
        },  
        focus: {
          description: "Switch your console focus to a different kubernetes resource type",
          usage: "e.g. focus secrets or focus configmaps etc",
          group: :kubernetes,
          console_only: true
        }
      }
    end
  end
end
