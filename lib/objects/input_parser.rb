class InputParser

  attr_reader :input

  def initialize(input, node)
    @input = input
    @node = node
  end

  def parse
    # Todo
    # if token without quotation marks matches a resource in scope, then return that object so can execute command on it?
    # OR it token:foo where token = object & foo method then, token_object.send(foo) ??? 

    if node_methods.any? && @input =~ /^(#{node_methods.join("|")}) (.+)$/i
      method = $1
      arguments = $2
      return do_parse(method, arguments)
    else
      return @input
    end     
  end

  private

  def node_methods
    # All methods expect (or may optionally have) one or more namespaces as arguments
    %w(cd helm ls workon disable ssh tree switch focus)  
  end

  def wrapped_methods
    # Methods where the whole string needs to be wrapped, rather than the individual namespaces
    # e.g cd "foo" or cd "foo:bar"
    %w(cd helm switch focus)
  end

  def do_parse(method, arguments)
    if wrapped_methods.include?(method)
      return "#{method} \"#{arguments}\""
    else
      arguments.gsub!(/([a-zA-Z\-0-9]+(?:[a-zA-Z\-0-9].+)*)/,"'\\1'")
      return "#{method} #{arguments}"
    end
  end
end
