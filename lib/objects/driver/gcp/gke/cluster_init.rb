module ::Bcome::Driver::Gcp::Gke::ClusterInit

  def register_cluster_in_config
    run_kubectl_config("config set-cluster #{name} --server=#{server}")
  end

  def register_cluster_certificate_in_config
    run_kubectl_config("config set clusters.#{name}.certificate-authority-data #{cluster_certificate}")
  end

  def register_user_in_config
    run_kubectl_config("config set-credentials #{username} --token=#{access_token}")
  end  

  def register_cluster_context
    run_kubectl_config("config set-context #{name} --cluster=#{name} --user=#{username}")
  end

  def access_token
    @node.network_driver.network_credentials[:access_token]
  end
end
