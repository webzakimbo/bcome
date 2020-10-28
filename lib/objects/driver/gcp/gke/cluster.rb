module ::Bcome::Driver::Gcp::Gke
  class Cluster

    # Note: Oauth only for now
    # Need to guard against this
    # Quite possible, we can ENFORCE oauth? And force them down the generic google oauth path with the not so secret client?
 
    def initialize(node)
      raise "Invalid collection class for #{self.class}" unless node.is_a?(::Bcome::Node::Collection::Kube)
      @node = node
    end  

    def bearer_token
      @token ||= get_bearer_token
    end

    def config
      @config ||= get_config
    end  


    private

    def get_config

      # Todo - http request to google endpoint based on get-container-stuff.rb
      # Todo - catch exceptions:
      #  invalid bearer token, so basically anything but a 200OK, we'll fail fast and show "Failed to retrieve Cluster config from GCP for <label> <error code> <message>"

    end

    def get_bearer_token
      authorize
      network_driver.network_credentials[:access_token]
    end

    def authorize
      network_driver.authorize
    end

    def network_driver
      @node.network_driver
    end

  end
end
