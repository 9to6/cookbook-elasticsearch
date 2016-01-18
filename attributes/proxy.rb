include_attribute "elasticsearch2::default"
include_attribute "elasticsearch2::nginx"

# Try to load data bag item 'elasticsearch2/aws' ------------------
#
users = Chef::DataBagItem.load('elasticsearch2', 'users')[node.chef_environment]['users'] rescue []
# ----------------------------------------------------------------

# === NGINX ===
# Allowed users are set based on data bag values, when it exists.
#
# It's possible to define the credentials directly in your node configuration, if your wish.
#
default.elasticsearch2[:nginx][:server_name]    = "elasticsearch2"
default.elasticsearch2[:nginx][:port]           = "8080"
default.elasticsearch2[:nginx][:dir]            = ( node.nginx[:dir]     rescue '/etc/nginx'     )
default.elasticsearch2[:nginx][:user]           = ( node.nginx[:user]    rescue 'nginx'          )
default.elasticsearch2[:nginx][:log_dir]        = ( node.nginx[:log_dir] rescue '/var/log/nginx' )
default.elasticsearch2[:nginx][:users]          = users
default.elasticsearch2[:nginx][:passwords_file] = "#{node.elasticsearch2[:path][:conf]}/passwords"

# Deny or allow authenticated access to cluster API.
#
# Set this to `true` if you want to use a tool like BigDesk
#
default.elasticsearch2[:nginx][:allow_cluster_api] = false
default.elasticsearch2[:nginx][:allow_shutdown_api] = false
default.elasticsearch2[:nginx][:allow_root_search] = false

# Allow responding to unauthorized requests for `/status`,
# returning `curl -I localhost:9200`
#
default.elasticsearch2[:nginx][:allow_status] = false

# Other Nginx proxy settings
#
default.elasticsearch2[:nginx][:client_max_body_size] = "50M"
default.elasticsearch2[:nginx][:location]             = "/"
default.elasticsearch2[:nginx][:ssl][:cert_file]      = nil
default.elasticsearch2[:nginx][:ssl][:key_file]       = nil
default.elasticsearch2[:nginx][:proxy_connect_timeout] = "60s"
default.elasticsearch2[:nginx][:proxy_read_timeout] = "60s"
default.elasticsearch2[:nginx][:proxy_send_timeout] = "60s"
