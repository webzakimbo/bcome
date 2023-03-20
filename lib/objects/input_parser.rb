class InputParser

  attr_reader :input

  def initialize(input, node)
    @input = input
    @node = node
  end

  def parse
    @input.strip!

    if alternative_command = alternative_mapped_command
      return alternative_command
    end

    resource, suffixes = @node.scan(@input)

    if resource
      if suffixes.any?
        eval_lookup = "resources.for_identifier('#{resource.identifier}')"
        return "#{eval_lookup}.send('#{suffixes.join(".")}'.to_sym)"
      else
        return "'#{resource.identifier}'"
      end
    end

    if @input =~ /^(#{node_methods.join("|")}) (.+)$/i
      method = $1
      arguments = $2
      return do_parse(method, arguments)
    else
      return @input
    end     
  end

  private

  def alternative_mapped_command
    return "back" if @input == "cd .."
    return nil
  end

  def node_methods
    # Methods that we may want to wrap so that we can do e.g. run command rather than run 'command'
    %w(cd helm ls workon enable disable ssh tree switch focus vrender vfocus run pseudo_tty select)  
  end

  def wrapped_methods
    # Methods where the whole string needs to be wrapped, rather than the individual namespaces
    # e.g cd "foo" or cd "foo:bar"
    %w(cd helm switch focus run select)
  end

  def do_parse(method, arguments)
    if wrapped_methods.include?(method)
      if arguments !~ /"/  
        return "#{method} \"#{arguments}\""
      else
        return "#{method} #{arguments}"
      end
    else
      arguments.gsub!(/([a-zA-Z\-0-9\._]+(?:[a-zA-Z\-0-9\._].+)*)/,"'\\1'")
      return "#{method} #{arguments}"
    end
  end
end
