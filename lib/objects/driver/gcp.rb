# frozen_string_literal: true

require 'google/apis/compute_beta'
require 'google/cloud/container'

module Bcome::Driver
  class Gcp < Bcome::Driver::Base
    APPLICATION_NAME = 'Bcome console'

    def initialize(*params)
      super
      validate_authentication_scheme
      validate_service_scopes unless auth_scheme_key == :basic_oauth
    end

    def matches_auth_config?(other_config)
      # Used to determine whether a particular network config matches one for an existing driver as far as is
      # required for authorization. 
      config.select{|k, v|
        auth_attributes.include?(k)
       } == other_config.select{|k, v|
        auth_attributes.include?(k)
      }
    end

    def auth_attributes
      [:zone, :type, :project, :authentication_scheme, :secrets_filename, :service_scopes, :service_account_credentials]
    end

    def pretty_provider_name
      'GCP'
    end

    def pretty_resource_location
      "#{@params[:project]}/#{@params[:zone]}"
    end

    def authorize(reauth = false)
      if reauth || !authentication_scheme.authorized?
        authenticated_service = get_authenticated_gcp_service(reauth)
        raise ::Bcome::Exception::Generic, 'GCP authentication process failed' unless authentication_scheme.authorized?
      end
      return authenticated_service
    end

    def reauthorize
      reauth = true
      authorize(reauth)
    end   

    def fetch_server_list(_filters)
      authorize 

      wrap_indicator type: :basic, title: loader_title, completed_title: loader_completed_title do
        begin
          @instances = do_fetch_server_list(_filters)
          signal_success
        rescue Exception => e
          signal_failure
          raise e
        end
      end
      @instances.items
    end

    def do_fetch_server_list(_filters)
      # Network filter key now called :filter. retained :list_filter for backwards compatibility.
      # Fallback is ""
      filters = (
        @params[:filters] || (
          @params[:list_filter] || ''
        )
      )

      gcp_service.list_instances(@params[:project], @params[:zone], filter: filters)
    rescue Google::Apis::AuthorizationError => e
      raise ::Bcome::Exception::CannotAuthenticateToGcp
    rescue Google::Apis::ClientError => e
      raise ::Bcome::Exception::Generic, "Namespace #{@node.namespace} / #{e.message}"
    rescue Google::Apis::TransmissionError => e
      raise ::Bcome::Exception::Generic, 'Cannot reach GCP - do you have an internet connection?'
    end

    def has_network_credentials?
      true
    end

    def network_credentials
      {
        access_token: access_token,
        project_name: @params[:project]
      }
    end

    protected

    def validate_authentication_scheme
      raise ::Bcome::Exception::MissingGcpAuthenticationScheme, "node #{@node.namespace}" if @params[:authentication_scheme].nil? || @params[:authentication_scheme].empty?
      raise ::Bcome::Exception::InvalidGcpAuthenticationScheme, "Invalid GCP authentication scheme '#{@params[:authentication_scheme]}' for node #{@node.namespace}" unless auth_scheme
    end
   
    def invalid_auth_scheme?
      !auth_schemes.keys.include?(@params[:authentication_scheme].to_sym)
    end

    def auth_scheme
      auth_schemes[@params[:authentication_scheme].to_sym]
    end

    def auth_schemes
      {
        basic_oauth: ::Bcome::Driver::Gcp::Authentication::Oauth::Basic,
        oauth: ::Bcome::Driver::Gcp::Authentication::Oauth::UserApplication,
        service_account: ::Bcome::Driver::Gcp::Authentication::ServiceAccount
      }
    end

    def compute_service
      @compute_service ||= ::Google::Apis::ComputeBeta::ComputeService.new
    end

    def get_authenticated_gcp_service(reauth = false)
      authentication_scheme.do!(reauth)
      compute_service
    end

    def auth_scheme_key
      @params[:authentication_scheme].to_sym
    end

    def authentication_scheme
      # Service scopes are specified directly from the network config
      # A minumum scope of https://www.googleapis.com/auth/compute.readonly is required in order to list resources.

      auth_scheme = auth_schemes[auth_scheme_key]
      raise ::Bcome::Exception::InvalidGcpAuthenticationScheme, "Invalid GCP authentication scheme '#{auth_scheme_key}' for node #{@node.namespace}" unless auth_scheme

      case auth_scheme_key
        when :basic_oauth
          setup_oauth_authenticator
        when :oauth
          setup_oauth_authenticator
        when :service_account
          @authentication_scheme ||= auth_scheme.new(compute_service, service_scopes, @node, @params[:service_account_credentials], self)
        else
          raise ::Bcome::Exception::InvalidGcpAuthenticationScheme, "Invalid GCP authentication scheme '#{auth_scheme_key}' for node #{@node.namespace}"
      end
    end

    def setup_oauth_authenticator
      client_config = ::Bcome::Driver::Gcp::Authentication::OauthClientConfig.new(service_scopes, oauth_filename)

      # Prevent second oauth flow during same session with same credentials, different inventory.
      # If we already have an outh authentication scheme for the same scopes & oauth credentials, then we'll return that one

      # If the scheme is set, return it
      return @authentication_scheme if @authentication_scheme

      # Look to see if we have an existing oauth scheme setup for the same scopes & credentials file
      if @authentication_scheme = ::Bcome::Driver::Gcp::Authentication::OauthSessionStore.instance.in_memory_session_for(client_config)
        @compute_service = @authentication_scheme.service
        return @authentication_scheme
      end

      # Otherwise, we'll create a new outh scheme and register it with the session store
      @authentication_scheme = auth_scheme.new(self, compute_service, client_config, @node)
      ::Bcome::Driver::Gcp::Authentication::OauthSessionStore.instance << @authentication_scheme
      @authentication_scheme
    end

    def oauth_filename
      @params[:secrets_path] || @params[:secrets_filename]
    end

    def gcp_service
      @gcp_service ||= get_authenticated_gcp_service
    end

    def access_token
      @access_token = gcp_service.authorization.access_token
      @access_token
    end
 
    def authorization
      gcp_service.authorization
    end

    def service_scopes
      @params[:service_scopes]
    end

    def validate_service_scopes
      raise ::Bcome::Exception::MissingGcpServiceScopes, 'Please define as minimum https://www.googleapis.com/auth/compute.readonly' unless has_service_scopes_defined?
    end

    def has_service_scopes_defined?
      service_scopes&.any?
    end
  end
end
