module Bcome::Orchestration::Catalogue
  class K8CronTrigger < Bcome::Orchestration::Base

    def execute
      puts "Triggering cron #{cron_name}".informational
      ap cron_job.labels
      cron_job.trigger!
    end

    def cron_job
      @cron_job ||= get_cron_job
    end

    def get_cron_job
      cron = cron_jobs.select{|cron| cron.identifier == cron_name }.first
      raise "Can't find cron #{cron_name}" unless cron
      return cron
    end

    def cron_jobs
      @node.retrieve :cronjobs
    end

    def cron_name
      raise "Missing argument 'cron_name'" unless @arguments[:cron_name]
      return @arguments[:cron_name]
    end
  end
end
