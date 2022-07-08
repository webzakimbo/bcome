# frozen_string_literal: true

module Bcome::Orchestration
  class InteractiveTerraform < Bcome::Orchestration::Base

    ## TODO - Refactor this.

    ## Contextual Terraform shell

    # * Provides access to the metadata framework, so that data may be shared between Orchestrative processes and Terraform
    # * Transparent authorization, by passing in cloud authorisation details from the bcome session
    # * Passes in SSH credentials directly, which can be used to bootstrap machines.
    # * Passes metadata from the bcome framework directly into Terraform, allowing data sharing between the rest of the framework

    QUIT = '\\q'
    COMMAND_PROMPT = "enter command or '#{QUIT}' to quit: " + 'terraform'.informational + "\s"

    def initialize(*params)
      super
      raise ::Bcome::Exception::Generic, "Missing terraform configuration directory #{path_to_env_config}" unless File.exist?(path_to_env_config)
    end

    def execute
      puts "\nContextual Terraform".bc_yellow.bold
      write_terraform_metadata
      show_intro_text
      wait_for_command_input
    end

    def show_intro_text

      puts "\nNamespace:\s" + @node.namespace.to_s.informational
      puts "Configuration Path:\s" + "#{path_to_env_config}/*".informational
      puts "\nConfigured metadata:\s"# + terraform_metadata.inspect.informational
      ap terraform_metadata, {indent: -2}

      puts "\n#{"Ready".bc_green.bold} Any commands you enter here will be passed directly to Terraform in your configuration scope (#{path_to_env_config}).\n\n"
    end

    def process_command(raw_command)
      full_command = command(raw_command)
      puts "\n"
      @node.execute_local(full_command)
      wait_for_command_input
    end

    def wait_for_command_input
      raw_command = wait_for_input
      process_command(raw_command) unless raw_command == QUIT
    end

    def wait_for_input(message = COMMAND_PROMPT)
      ::Readline.readline("#{message}", true).squeeze('').to_s
    end

    def terraform_metadata
      @terraform_metadata ||= @node.metadata.fetch('terraform', @node.metadata.fetch(:terraform, {}))
    end

    def write_terraform_metadata
      ## Get the terraform variables for this stack, and merge in with our networking & ssh credentials
      terraform_vars = terraform_metadata

      if @node.network_driver.has_network_credentials?
        network_credentials = @node.network_driver.network_credentials
        terraform_vars.merge!(network_credentials)
        # We do not persist the access token
        terraform_vars.delete(:access_token) if @node.network_driver.is_a?(::Bcome::Driver::Gcp)
      end

      terraform_vars[:ssh_user] = @node.ssh_driver.user

      full_path_to_metadata = "#{path_to_env_config}/#{metadata_tf_filename}"
      puts "Extracting metadata: ".informational + full_path_to_metadata + "\n"
      File.open(full_path_to_metadata, 'w') { |f| f.write(terraform_vars.to_json) }
    end

    def metadata_tf_filename
      "bcome-tf-metadata.json"
    end

    def var_string
      @var_string ||= form_var_string
    end

    def backend_config_parameter_string
      ## Backend configs are loaded before Terraform Core which means that we cannot use variables directly in our backend config.
      ## This is a pain as we'll have authorised with GCP via the console, and so all sesssion have an access token readily available.
      ## This patch passes the access token directly to terraform as a parameter.

      ## GCP only for now. Support for AWS may come later as needed/requested.
      return '' unless @node.network_driver.is_a?(::Bcome::Driver::Gcp)

      "\s-backend-config \"access_token=#{@node.network_driver.network_credentials[:access_token]}\"\s"
    end

    # Retrieve the path to the terraform configurations for this stack
    def path_to_env_config
      @path_to_env_config ||= "terraform/environments/#{@node.namespace.gsub(':', '_')}"
    end

    # Formulate a terraform command

    def command(raw_command) ## TODO - CLEAN UP
      if raw_command =~ Regexp.new(/^apply$|plan|destroy|refresh|import/)

        params = "-var-file=\"#{metadata_tf_filename}\""

        if @node.network_driver.is_a?(::Bcome::Driver::Gcp)
          params += "\s-var access_token=#{@node.network_driver.network_credentials[:access_token]}" 
        end

       if raw_command =~ /^import/
         raw_command =~ /([^\s]+)\s(.+)/
         verb = $1
         resource = $2
         cmd = "cd #{path_to_env_config} ; terraform #{verb} #{params} #{resource}"
        else
          cmd = "cd #{path_to_env_config} ; terraform #{raw_command} #{params}"
        end
      else
        cmd = "cd #{path_to_env_config} ; terraform #{raw_command}"
      end

      puts "\n" + cmd.informational + "\n"
      return cmd
    end
  end
end
