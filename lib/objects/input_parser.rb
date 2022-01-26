class InputParser

  attr_reader :input

  def initialize(input, node)
    @input = input
    @node = node
  end

  def parse
    @input.strip!

    ## Better UI UX - drill down by id name and method foo.bar.method
    if resource = @node.resources.for_identifier(@input)
      # While input matches a resource; return it
      return "resources.for_identifier(\"#{@input}\")"
    else
      @tokens = @input.split(".")
      if @tokens && @node.resources.for_identifier(@tokens.first)
        suffixes = @tokens[1..@tokens.size]
        to_eval_suffixes = suffixes.collect{|token| "send('#{token}'.to_sym)" }.join(".")
        return "resources.for_identifier('#{@tokens.first}').#{to_eval_suffixes}"
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
      arguments.gsub!(/([a-zA-Z\-0-9\.]+(?:[a-zA-Z\-0-9\.].+)*)/,"'\\1'")
      return "#{method} #{arguments}"
    end
  end
end
