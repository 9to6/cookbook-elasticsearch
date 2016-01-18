# Load settings from data bag 'elasticsearch2/settings'
#
settings = Chef::DataBagItem.load('elasticsearch2', 'settings')[node.chef_environment] rescue {}
Chef::Log.debug "Loaded settings: #{settings.inspect}"

# Initialize the node attributes with node attributes merged with data bag attributes
#
node.default[:elasticsearch2] ||= {}
node.normal[:elasticsearch2]  ||= {}

include_attribute 'elasticsearch2::customize'

node.normal[:elasticsearch2]    = DeepMerge.merge(node.default[:elasticsearch2].to_hash, node.normal[:elasticsearch2].to_hash)
node.normal[:elasticsearch2]    = DeepMerge.merge(node.normal[:elasticsearch2].to_hash, settings.to_hash)


# === VERSION AND LOCATION
#
default.elasticsearch2[:version]       = "1.6.0"
default.elasticsearch2[:host]          = "http://download.elastic.co"
default.elasticsearch2[:repository]    = "elasticsearch/elasticsearch"
default.elasticsearch2[:filename]      = nil
default.elasticsearch2[:download_url]  = nil

# === NAMING
#
default.elasticsearch2[:cluster][:name] = 'elasticsearch2'
default.elasticsearch2[:node][:name]    = node.name

# === USER & PATHS
#
default.elasticsearch2[:dir]       = "/usr/local"
default.elasticsearch2[:bindir]    = "/usr/local/bin"
default.elasticsearch2[:user]      = "elasticsearch"
default.elasticsearch2[:uid]       = nil
default.elasticsearch2[:gid]       = nil

default.elasticsearch2[:path][:conf] = "/usr/local/etc/elasticsearch"
default.elasticsearch2[:path][:data] = "/usr/local/var/data/elasticsearch"
default.elasticsearch2[:path][:logs] = "/usr/local/var/log/elasticsearch"

default.elasticsearch2[:pid_path]  = "/usr/local/var/run"
default.elasticsearch2[:pid_file]  = "#{node.elasticsearch2[:pid_path]}/#{node.elasticsearch2[:node][:name].to_s.gsub(/\W/, '_')}.pid"

default.elasticsearch2[:templates][:elasticsearch_env] = "elasticsearch-env.sh.erb"
default.elasticsearch2[:templates][:elasticsearch_yml] = "elasticsearch.yml.erb"
default.elasticsearch2[:templates][:logging_yml]       = "logging.yml.erb"

# === MEMORY
#
# Maximum amount of memory to use is automatically computed as one half of total available memory on the machine.
# You may choose to set it in your node/role configuration instead.
#
allocated_memory = "#{(node.memory.total.to_i * 0.5 ).floor / 1024}m"
default.elasticsearch2[:allocated_memory] = allocated_memory

# === GARBAGE COLLECTION SETTINGS
#
default.elasticsearch2[:gc_settings] =<<-CONFIG
  -XX:+UseParNewGC
  -XX:+UseConcMarkSweepGC
  -XX:CMSInitiatingOccupancyFraction=75
  -XX:+UseCMSInitiatingOccupancyOnly
  -XX:+HeapDumpOnOutOfMemoryError
CONFIG

# === LIMITS
#
# By default, the `mlockall` is set to true: on weak machines and Vagrant boxes,
# you may want to disable it.
#
default.elasticsearch2[:bootstrap][:mlockall] = ( node.memory.total.to_i >= 1048576 ? true : false )
default.elasticsearch2[:limits][:memlock]  = 'unlimited'
default.elasticsearch2[:limits][:nofile]   = '64000'
default.elasticsearch2[:limits][:mapcount] = '262144'

# === PRODUCTION SETTINGS
#
default.elasticsearch2[:index][:mapper][:dynamic]   = true
default.elasticsearch2[:action][:auto_create_index] = true
default.elasticsearch2[:action][:disable_delete_all_indices] = true
default.elasticsearch2[:node][:max_local_storage_nodes] = 1

default.elasticsearch2[:discovery][:zen][:ping][:multicast][:enabled] = true
default.elasticsearch2[:discovery][:zen][:minimum_master_nodes] = 1
default.elasticsearch2[:gateway][:type] = 'local'
default.elasticsearch2[:gateway][:expected_nodes] = 1

default.elasticsearch2[:thread_stack_size] = "256k"

default.elasticsearch2[:env_options] = ""

default.elasticsearch2[:indices][:breaker][:fielddata][:limit] = "85%"
default.elasticsearch2[:indices][:breaker][:request][:limit] = "55%"
default.elasticsearch2[:indices][:breaker][:total][:limit] = "90%"
default.elasticsearch2[:indices][:fielddata][:cache][:size] = "75%"

default.elasticsearch2[:http][:max_content_length] = "1gb"
default.elasticsearch2[:cluster][:routing][:allocation][:disk][:watermark][:low] = "90%"
default.elasticsearch2[:cluster][:routing][:allocation][:disk][:watermark][:high] = "95%"
default.elasticsearch2[:cluster][:routing][:allocation][:balance][:shard] = 0.1
default.elasticsearch2[:cluster][:routing][:allocation][:balance][:index] = 0.9
default.elasticsearch2[:cluster][:routing][:allocation][:balance][:primary] = 0.0
default.elasticsearch2[:cluster][:routing][:allocation][:balance][:threshold] = 0.8

  # 1 for not using SSD
default.elasticsearch2[:index][:merge][:scheduler][:max_thread_count] = 1

  # 1GB for indexing performance (ES default : 200MB)
default.elasticsearch2[:index][:translog][:flush_threshold_size] = "1GB"

  # for using Kibana
default.elasticsearch2[:http][:cors][:enabled] = true

# === OTHER SETTINGS
#
default.elasticsearch2[:skip_restart] = false
default.elasticsearch2[:skip_start] = false

# === PORT
#
default.elasticsearch2[:http][:port] = 9200

# === CUSTOM CONFIGURATION
#
default.elasticsearch2[:custom_config] = {}

# === LOGGING
#
# See `attributes/logging.rb`
#
default.elasticsearch2[:logging] = {}

# --------------------------------------------------
# NOTE: Setting the attributes for elasticsearch.yml
# --------------------------------------------------
#
# The template uses the `print_value` extension method to print attributes with a "truthy"
# value, set either in data bags, node attributes, role override attributes, etc.
#
# It is possible to set *any* configuration value exposed by the Elasticsearch configuration file.
#
# For example:
#
#     <%= print_value 'cluster.routing.allocation.node_concurrent_recoveries' -%>
#
# will print a line:
#
#     cluster.routing.allocation.node_concurrent_recoveries: <VALUE>
#
# if the either of following node attributes is set:
#
# * `node.cluster.routing.allocation.node_concurrent_recoveries`
# * `node['cluster.routing.allocation.node_concurrent_recoveries']`
#
# The default attributes set by the cookbook configure a minimal set inferred from the environment
# (eg. memory settings, node name), or reasonable defaults for production.
#
# The template is based on the elasticsearch.yml file from the Elasticsearch distribution;
# to set other configurations, set the `node.elasticsearch2[:custom_config]` attribute in the
# node configuration, `elasticsearch2/settings` data bag, role/environment definition, etc:
#
#     // ...
#     'threadpool.index.type' => 'fixed',
#     'threadpool.index.size' => '2'
#     // ...
#
