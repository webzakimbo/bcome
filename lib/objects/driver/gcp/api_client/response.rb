module Bcome::Driver::Gcp::ApiClient
  class Response

    def initialize(raw_response)
      @raw_response = raw_response
    end

    def success?
      http_code == 200
    end  

    def http_code
      @raw_response.code.to_i
    end

    def json_body
      @json_body ||= JSON.parse(@raw_response.body)
    end

    def error_message
      if in_error?
        json_body["error"]["message"]
      else
        return "unexpected exception"
      end
    end

    def error_status
      if in_error?
        json_body["error"]["status"]
      else
         "unknown status"
      end
    end

    def in_error?
      json_body && json_body["error"]
    end
  end
end
