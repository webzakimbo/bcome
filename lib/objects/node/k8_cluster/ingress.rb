# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class Ingress < Bcome::Node::K8Cluster::Child

    def rules
      @rules ||= get_rules
    end

    def pathway_data(*params)
      map = {}
      hosts.compact.each do |host|
        map[host.bc_cyan] = host_tree_nodes(host)
      end
      return map
    end

    def host_tree_nodes(host)
      # get the rules for this host
      rules_for_host = rules.select{|rule| 
        rule.host == host
      }

      map = {}
      rules_for_host.each do |rule|
        map.deep_merge!(rule.pathway_data)
      end
      return map
    end
  
    def hosts
      rules.collect{|rule| rule.host }
    end  

    def for_service?(query_service)
      for_service = services.collect{|service| 
        service == query_service 
       }.flatten.any?

      return for_service
    end

    private

    def services
      rules.collect(&:services).flatten
    end
 
    def get_rules
      # Conventionally, an ingress without rules will send all traffic to a default backend.
      # This is not yet handled as far as mapping traffic is concerned.
      return [] unless spec["rules"]

      spec["rules"].collect{|rule_config|
        ::Bcome::Node::K8Cluster::Utilities::IngressRule.new(self, rule_config)
      } 
    end  
  end
end
