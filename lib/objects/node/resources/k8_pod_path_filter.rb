module ::Bcome::Node::Resources
  class K8PathFilter

    def initialize(node, config)
      @node = node
      validate(config)
      begin
        @matcher = Regexp.new(config[:regexp_matcher])
      rescue TypeError
        raise ::Bcome::Exception::Generic, "Invalid regexp matcher parsing filter #{config}."
      end

      @path = JsonPath.new(config[:jsonpath])
    end

    def json
      @json ||= @node.views[:raw_data].to_json
    end

    def match?
      !@matcher.match(path_data).nil?
    end

    def path_data
      @path.on(json).first
    end
   
    private

    def validate(config)
      raise ::Bcome::Exception::Generic, "Missing regexp matcher parsing filter #{config}" unless config[:regexp_matcher]
      raise ::Bcome::Exception::Generic, "Missing json path parsing filter #{config}" unless config[:jsonpath]
      raise ::Bcome::Exception::Generic, "Invalid json path for filter #{config}. Expecting String" unless config[:jsonpath].is_a?(String)
    end
  end
end
