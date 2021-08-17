module Bcome::Node::K8Cluster::Collection
  class Gcp < Base

    def cluster_id
      "#{cluster_name}/#{project}:#{region}"
    end

    def region
      cluster[:region]
    end

    def project
      network[:project]
    end

    def required_attributes
      [:cluster_name, :region, :project]
    end

    def do_get_credentials
      wrap_indicator type: :basic, title: "Authorising\s" + "GCP\s".bc_blue.bold + cluster_id.underline, completed_title: 'done' do
        begin
          @k8_cluster = ::Bcome::Driver::Gcp::Gke::Cluster.new(self)
        rescue ::Bcome::Exception::ReauthGcp
          network_driver.reauthorize
        rescue ::Bcome::Exception::GcpResourceNotFound
          raise ::Bcome::Exception::Generic, "Cluster #{cluster_id} not found - is your network configuration correct?"
        rescue StandardError => e
          raise ::Bcome::Exception::Generic, "Could not retrieve credentials for #{cluster_id}. Failed with: #{e.class} #{e.message}"
        end
      end
    end
  end
end