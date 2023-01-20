# frozen_string_literal: true

require 'cronex'

module Bcome::Node::K8Cluster
  class CronJob < Bcome::Node::K8Cluster::Child

    def tree_identifier
      "#{identifier.resource_key} (#{human_schedule})"
    end

    def trigger!(should_prompt_for_confirmation = true)
      job_name = "#{identifier}-#{Time.now.to_i}"

      parent.delegated_kubectl_cmd(create_job_command(job_name))
      puts "Job name: #{job_name}"
    end
    alias :trigger :trigger!


    def enabled_menu_items
      (super + %i[trigger])
    end

    def menu_items
      base_items = super.dup

      base_items[:trigger] = {
        description: "Trigger this cronjob to run immediately",
        group: :kubernetes
      }
      base_items
    end
 
    def schedule
      raw_config_data["spec"]["schedule"]
    end

    def human_schedule
      @human ||= Cronex::ExpressionDescriptor.new(schedule).description
    end

    def create_job_command(job_name)
      "create job --from=cronjob/#{identifier} #{job_name}"
    end

    def labels
      raw_config_data["metadata"]["labels"]
    end
  end
end
