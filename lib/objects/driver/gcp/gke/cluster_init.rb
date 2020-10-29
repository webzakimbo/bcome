module ::Bcome::Driver::Gcp::Gke::ClusterInit

  def register_cluster_in_config
    run_kubectl_config("config set-cluster #{name} --server=#{server}")
  end

  def register_cluster_certificate_in_config
    run_kubectl_config("config set clusters.#{name}.certificate-authority-data #{cluster_certificate}")
  end

  def register_user_in_config
    run_kubectl_config("config set credentials #{username} --username=#{username}")
  end  

end
