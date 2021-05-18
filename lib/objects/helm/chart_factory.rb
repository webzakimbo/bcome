module Bcome::Helm
  class ChartFactory

    class << self
      def apply_from_config_by_key(config_key, node)
        charts_config = node.metadata.fetch(config_key)
        charts = charts_config.collect{|config|
          ::Bcome::Helm::Chart.new(config)
        }
        apply(charts, node) 
      end

      def apply(charts, node)
        factory = new(charts, node)
        factory.apply
      end
    end

    def initialize(charts, node)
      @charts = charts
      @node = node
    end

    def apply
      @node.helm "repo update"
      @charts.each {|chart| chart.apply(@node) }
    end
  end
end
