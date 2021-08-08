# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class CronJob < Bcome::Node::K8Cluster::Child

    def trigger!(should_prompt_for_confirmation = true)
      job_name = "manual-job-#{Time.now.to_i}"

      parent.delegated_kubectl_cmd(create_job_command(job_name))
      puts "Job name: #{job_name}"
    end

    def create_job_command(job_name)
      "create job --from=cronjob/#{identifier} #{job_name}"
    end

    def labels
      raw_config_data["metadata"]["labels"]
    end
  end
end
