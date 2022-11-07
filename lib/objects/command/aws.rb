module Bcome::Command
  class Aws

    AWS_BINARY="aws".freeze

    def self.run(command, network_driver) 
      runner = new(command, network_driver)
      runner.run
    end

    def initialize(command, network_driver)
      ::Bcome::EnsureBinary.do(AWS_BINARY)
      @network_driver = network_driver
      @command = command
    end

    def run
      delegated_command_runner = ::Bcome::Command::Local.run(full_command)
      return delegated_command_runner if delegated_command_runner.is_success?
      raise ::Bcome::Exception::Generic, delegated_command_runner.stderr 
    end

    def full_command
      "#{credentials_string} #{AWS_BINARY} #{@command}"
    end
 
    def credential_map
      { 
        access_key: "AWS_ACCESS_KEY_ID", 
        secret_key: "AWS_SECRET_ACCESS_KEY", 
        session_token: "AWS_SESSION_TOKEN" 
      }      
    end

    def credentials
      @network_driver.network_credentials
    end  

    def credentials_string
      cred_string = ""
      credential_map.each do |credential_key, environment_key|
        cred_string += "#{environment_key}=#{credentials[credential_key]}\s" if credentials.has_key?(credential_key)
      end
      return cred_string
    end  
  end
end