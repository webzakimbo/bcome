# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class CronJob < Bcome::Node::K8Cluster::Child

    def trigger!
      job_name = "manual-job-#{Time.now.to_i}"
      command = create_job_command(job_name)
      puts "Creating new job: '#{job_name}' from cronjob '#{identifier}'".informational
      parent.run_kc(command)
    end

    def create_job_command(job_name)
      "create job --from=cronjob/#{identifier} #{job_name}"
    end

    def labels
      raw_config_data["metadata"]["labels"]
    end
  end
end
