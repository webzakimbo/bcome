module ::Bcome
  class NodeSelection

    include ::Singleton

    def initialize
      @bucket = []
    end

    def selection
      @bucket
    end

    def clear!
      @bucket = []
    end

    def active?
      !@bucket.empty?
    end
 
    def add(node)
      @bucket += node.do_load_machines
      @bucket.flatten!
      @bucket.uniq!
    end

    def remove(node)
      @bucket -= [node]
    end

    def includes?(node)
      @bucket.include?(node)  
    end

  end
end
