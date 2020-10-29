module Bcome::Driver::Gcp::ApiClient
  class Request

    class << self
      def do(uri, node)
        return new(uri, node).do
      end 
    end
 
    def initialize(uri, node)
      @uri = uri
      @node = node
      @network_driver = @node.network_driver
    end

    def bearer_token
      @bearer_token ||= get_bearer_token
    end

    def headers
      {
        "Authorization": "Bearer #{bearer_token}",
        "Content-Type": "application/json"
      }
    end

    def do
      response = make_request
      if response.success?
        return response.json_body
      else
        raise ::Bcome::Exception::Generic, "Status #{response.error_status} received from GCP API for node #{@node.namespace}.\nHTTP #{response.http_code} \nMessage: #{response.error_message}"
      end
    end
   
    private

    def make_request
      @raw_response = nil
      Net::HTTP.start(@uri.host, @uri.port,
        :use_ssl => @uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new @uri

        headers.each do |header_key, header_value|
          request[header_key] = header_value
        end

        @raw_response = http.request request
      end
      return ::Bcome::Driver::Gcp::ApiClient::Response.new(@raw_response)
    end

    def get_bearer_token
      authorize
      @network_driver.network_credentials[:access_token]
    end

    def authorize
      @network_driver.authorize
    end

  end
end
