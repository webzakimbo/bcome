# frozen_string_literal: true

module Bcome::Node::K8Cluster
  class CronJob < Bcome::Node::K8Cluster::Child

    def trigger!(should_prompt_for_confirmation = true)
      job_name = "manual-job-#{Time.now.to_i}"

      if should_prompt_for_confirmation && user_assents?
        command = create_job_command(job_name)
        puts "Creating new job: '#{job_name}' from cronjob '#{identifier}'".informational
        parent.run_kc(command)
      end
    end

    def create_job_command(job_name)
      "create job --from=cronjob/#{identifier} #{job_name}"
    end

    def labels
      raw_config_data["metadata"]["labels"]
    end

    private

    def user_assents?
      prompt_for_confirmation("\nAre you sure you want to trigger cronjob '#{identifier}'? It will be run immediately. [y|n]\s")
    end

    # TODO - following should be a module in the Interactive namespace, and then included here and
    # in interactive session items
    def prompt_for_confirmation(message)
      answer = get_input(message)
      answer == 'y'
    end

    def get_input(message = terminal_prompt)
      ::Reline.readline("#{message}", true).squeeze('').to_s
    end

  end
end
