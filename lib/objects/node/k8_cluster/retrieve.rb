module Bcome::Node::K8Cluster::Retrieve

  def retrieve(crd_keys)
    fetched_resources = []

    raw_resources = get_kubectl_resource(crd_keys)

    items = {}
    raw_resources.each do |raw_resource|
      resource_type = raw_resource["kind"]
      resource_klass = resource_klasses[resource_type] ? resource_klasses[resource_type] : crd_resource_klass
      fetched_resources << add_resource(resource_klass, resource_type, raw_resource)
    end
    return fetched_resources
  end

  def get_kubectl_resource(crd_keys)
    resource_names = crd_keys.is_a?(Array) ? crd_keys.join(",") : crd_keys

    command = "get #{resource_names}"
    command += "\s--all-namespaces" if is_a?(::Bcome::Node::K8Cluster::Collection::Base)
    data = run_kc(command)

    raise ::Bcome::Exception::Generic, "No items returned from call to 'get #{crd_key}'" if !data.is_a?(Hash) && data.has_key?(:items)
    items = data["items"]

    return items
  end

end
