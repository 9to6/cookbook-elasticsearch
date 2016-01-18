[Chef::Recipe, Chef::Resource].each { |l| l.send :include, ::Extensions }

Erubis::Context.send(:include, Extensions::Templates)

elasticsearch2 = "elasticsearch-#{node.elasticsearch2[:version]}"

include_recipe "elasticsearch2::curl"
include_recipe "ark"

# Create user and group
#
group node.elasticsearch2[:user] do
  gid node.elasticsearch2[:gid]
  action :create
  system true
end

user node.elasticsearch2[:user] do
  comment "ElasticSearch User"
  home    "#{node.elasticsearch2[:dir]}/elasticsearch"
  shell   "/bin/bash"
  uid     node.elasticsearch2[:uid]
  gid     node.elasticsearch2[:user]
  supports :manage_home => false
  action  :create
  system true
end

# FIX: Work around the fact that Chef creates the directory even for `manage_home: false`
bash "remove the elasticsearch user home" do
  user    'root'
  code    "rm -rf  #{node.elasticsearch2[:dir]}/elasticsearch"
  not_if  { ::File.symlink?("#{node.elasticsearch2[:dir]}/elasticsearch") }
  only_if { ::File.directory?("#{node.elasticsearch2[:dir]}/elasticsearch") }
end


# Create ES directories
#
[ node.elasticsearch2[:path][:logs] ].each do |path|
  directory path do
    owner node.elasticsearch2[:user] and group node.elasticsearch2[:user] and mode 0755
    recursive true
    action :create
  end
end

directory node.elasticsearch2[:pid_path] do
  mode '0755'
  recursive true
end

# Create data path directories
#
data_paths = node.elasticsearch2[:path][:data].is_a?(Array) ? node.elasticsearch2[:path][:data] : node.elasticsearch2[:path][:data].split(',')

data_paths.each do |path|
  directory path.strip do
    owner node.elasticsearch2[:user] and group node.elasticsearch2[:user] and mode 0755
    recursive true
    action :create
  end
end

# Create service
#
template "/etc/init.d/elasticsearch" do
  source "elasticsearch.init.erb"
  owner 'root' and mode 0755
end

service "elasticsearch" do
  supports :status => true, :restart => true
  action [ :enable ]
end

# Download, extract, symlink the elasticsearch libraries and binaries
#
ark_prefix_root = node.elasticsearch2[:dir] || node.ark[:prefix_root]
ark_prefix_home = node.elasticsearch2[:dir] || node.ark[:prefix_home]

filename = node.elasticsearch2[:filename] || "elasticsearch-#{node.elasticsearch2[:version]}.tar.gz"
download_url = node.elasticsearch2[:download_url] || [node.elasticsearch2[:host],
                node.elasticsearch2[:repository], filename].join('/')

ark "elasticsearch" do
  url   download_url
  owner node.elasticsearch2[:user]
  group node.elasticsearch2[:user]
  version node.elasticsearch2[:version]
  has_binaries ['bin/elasticsearch', 'bin/plugin']
  checksum node.elasticsearch2[:checksum]
  prefix_root   ark_prefix_root
  prefix_home   ark_prefix_home

  notifies :start,   'service[elasticsearch]' unless node.elasticsearch2[:skip_start]
  notifies :restart, 'service[elasticsearch]' unless node.elasticsearch2[:skip_restart]

  not_if do
    link   = "#{node.elasticsearch2[:dir]}/elasticsearch"
    target = "#{node.elasticsearch2[:dir]}/elasticsearch-#{node.elasticsearch2[:version]}"
    binary = "#{target}/bin/elasticsearch"

    ::File.directory?(link) && ::File.symlink?(link) && ::File.readlink(link) == target && ::File.exists?(binary)
  end
end

# Increase open file and memory limits
#
bash "enable user limits" do
  user 'root'

  code <<-END.gsub(/^    /, '')
    echo 'session    required   pam_limits.so' >> /etc/pam.d/su
  END

  not_if { ::File.read("/etc/pam.d/su").match(/^session    required   pam_limits\.so/) }
end

file "/etc/security/limits.d/10-elasticsearch.conf" do
  content <<-END.gsub(/^    /, '')
    #{node.elasticsearch2.fetch(:user, "elasticsearch")}     -    nofile    #{node.elasticsearch2[:limits][:nofile]}
    #{node.elasticsearch2.fetch(:user, "elasticsearch")}     -    memlock   #{node.elasticsearch2[:limits][:memlock]}
  END

  notifies :write, 'log[increase limits]', :immediately
end

log "increase limits" do
  message "increased limits for the elasticsearch user"
  action :nothing
end

# Create file with ES environment variables
#
template "elasticsearch-env.sh" do
  path   "#{node.elasticsearch2[:path][:conf]}/elasticsearch-env.sh"
  source node.elasticsearch2[:templates][:elasticsearch_env]
  owner  node.elasticsearch2[:user] and group node.elasticsearch2[:user] and mode 0755

  notifies :restart, 'service[elasticsearch]' unless node.elasticsearch2[:skip_restart]
end

# Create ES config file
#
template "elasticsearch.yml" do
  path   "#{node.elasticsearch2[:path][:conf]}/elasticsearch.yml"
  source node.elasticsearch2[:templates][:elasticsearch_yml]
  owner  node.elasticsearch2[:user] and group node.elasticsearch2[:user] and mode 0755

  notifies :restart, 'service[elasticsearch]' unless node.elasticsearch2[:skip_restart]
end

# Create ES logging file
#
template "logging.yml" do
  path   "#{node.elasticsearch2[:path][:conf]}/logging.yml"
  source node.elasticsearch2[:templates][:logging_yml]
  owner  node.elasticsearch2[:user] and group node.elasticsearch2[:user] and mode 0755

  notifies :restart, 'service[elasticsearch]' unless node.elasticsearch2[:skip_restart]
end
