# frozen_string_literal: true

module Bcome::Node::Server::Dynamic
  class Ec2 < Bcome::Node::Server::Dynamic::Base
    class << self
      def dynamic_server_type
        :ec2
      end

      def new_from_fog_instance(fog_instance, parent)
        identifier = fog_instance.tags['Name']

        params = {
          identifier: identifier,
          ec2_id: fog_instance.id,
          internal_ip_address: fog_instance.private_ip_address,
          public_ip_address: fog_instance.public_ip_address,
          role: fog_instance.tags['function'],
          description: "EC2 server - #{identifier}",
          ec2_server: fog_instance
        }

        new(parent: parent, views: params)
      end
    end

    def list_attributes
      super.merge({
        "ec2_id": :ec2_id,     
      })
    end

    def host
      'ec2'
    end

    def do_generate_cloud_tags
      raw_tags = cloud_server ? cloud_server.tags.deep_symbolize_keys : {}
      ::Bcome::Node::Meta::Cloud.new(raw_tags)
    end

    def cloud_server
      views[:ec2_server]
    end
  end
end
