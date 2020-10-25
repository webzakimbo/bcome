module Bcome::Initialization::PrepopulatedConfigs

  def prepopulated_path_contents(path)
    return config_contents[path.to_sym]
  end

  def config_contents
    {
      '.gauth/googles-not-so-secret-client-secrets.json': gcp_not_so_secret_config_contents 
    }
  end

  def gcp_not_so_secret_config_contents
    return <<EOF
{
  "installed":
  {
    "client_id": "32555940559.apps.googleusercontent.com",
    "client_secret": "ZmssLNjJy2998hD4CTg2ejr2",
    "type": "authorized_user"
  }
}
EOF
  end


end
