# Load settings from data bag 'elasticsearch/settings'
#
settings = Chef::DataBagItem.load('elasticsearch', 'settings')[node.chef_environment] rescue {}
Chef::Log.debug "Loaded settings: #{settings.inspect}"

# Initialize the node attributes with node attributes merged with data bag attributes
#
node.default[:elasticsearch] ||= {}
node.normal[:elasticsearch]  ||= {}

include_attribute 'elasticsearch::customize'

node.normal[:elasticsearch]    = DeepMerge.merge(node.default[:elasticsearch].to_hash, node.normal[:elasticsearch].to_hash)
node.normal[:elasticsearch]    = DeepMerge.merge(node.normal[:elasticsearch].to_hash, settings.to_hash)


# === VERSION AND LOCATION
#
default.elasticsearch[:version]       = "1.6.0"
default.elasticsearch[:host]          = "http://download.elastic.co"
default.elasticsearch[:repository]    = "elasticsearch/elasticsearch"
default.elasticsearch[:filename]      = nil
default.elasticsearch[:download_url]  = nil

# === NAMING
#
default.elasticsearch[:cluster][:name] = 'elasticsearch'
default.elasticsearch[:node][:name]    = node.name

# === USER & PATHS
#
default.elasticsearch[:dir]       = "/usr/local"
default.elasticsearch[:bindir]    = "/usr/local/bin"
default.elasticsearch[:user]      = "elasticsearch"
default.elasticsearch[:uid]       = nil
default.elasticsearch[:gid]       = nil

default.elasticsearch[:path][:conf] = "/usr/local/etc/elasticsearch"
default.elasticsearch[:path][:data] = "/usr/local/var/data/elasticsearch"
default.elasticsearch[:path][:logs] = "/usr/local/var/log/elasticsearch"

default.elasticsearch[:pid_path]  = "/usr/local/var/run"
default.elasticsearch[:pid_file]  = "#{node.elasticsearch[:pid_path]}/#{node.elasticsearch[:node][:name].to_s.gsub(/\W/, '_')}.pid"

default.elasticsearch[:templates][:elasticsearch_env] = "elasticsearch-env.sh.erb"
default.elasticsearch[:templates][:elasticsearch_yml] = "elasticsearch.yml.erb"
default.elasticsearch[:templates][:logging_yml]       = "logging.yml.erb"

# === MEMORY
#
# Maximum amount of memory to use is automatically computed as one half of total available memory on the machine.
# You may choose to set it in your node/role configuration instead.
#
allocated_memory = "#{(node.memory.total.to_i * 0.5 ).floor / 1024}m"
default.elasticsearch[:allocated_memory] = allocated_memory

# === GARBAGE COLLECTION SETTINGS
#
default.elasticsearch[:gc_settings] =<<-CONFIG
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
default.elasticsearch[:bootstrap][:mlockall] = ( node.memory.total.to_i >= 1048576 ? true : false )
default.elasticsearch[:limits][:memlock]  = 'unlimited'
default.elasticsearch[:limits][:nofile]   = '64000'
default.elasticsearch[:limits][:mapcount] = '262144'

# === PRODUCTION SETTINGS
#
default.elasticsearch[:index][:mapper][:dynamic]   = true
default.elasticsearch[:action][:auto_create_index] = true
default.elasticsearch[:action][:disable_delete_all_indices] = true
default.elasticsearch[:node][:max_local_storage_nodes] = 1

default.elasticsearch[:discovery][:zen][:ping][:multicast][:enabled] = true
default.elasticsearch[:discovery][:zen][:minimum_master_nodes] = 1
default.elasticsearch[:gateway][:type] = 'local'
default.elasticsearch[:gateway][:expected_nodes] = 1

default.elasticsearch[:thread_stack_size] = "256k"

default.elasticsearch[:env_options] = ""

default.elasticsearch[:indices][:breaker][:fielddata][:limit] = "60%" #"85%"
default.elasticsearch[:indices][:breaker][:request][:limit] = "40%" #"55%"
default.elasticsearch[:indices][:breaker][:total][:limit] = "70%" #"90%"
default.elasticsearch[:indices][:store][:throttle][:type] = "merge"
default.elasticsearch[:indices][:store][:throttle][:max_bytes_per_sec] = "20mb"

default.elasticsearch[:http][:max_content_length] = "1gb"
default.elasticsearch[:cluster][:routing][:allocation][:disk][:watermark][:low] = "90%"
default.elasticsearch[:cluster][:routing][:allocation][:disk][:watermark][:high] = "95%"
default.elasticsearch[:cluster][:routing][:allocation][:balance][:shard] = 0.1
default.elasticsearch[:cluster][:routing][:allocation][:balance][:index] = 0.9
default.elasticsearch[:cluster][:routing][:allocation][:balance][:primary] = 0.0
default.elasticsearch[:cluster][:routing][:allocation][:balance][:threshold] = 1.0 #0.8

default.elasticsearch[:threadpool][:bulk][:queue_size] = 5000

  # 1 for not using SSD
default.elasticsearch[:index][:merge][:scheduler][:max_thread_count] = 1

  # 1GB for indexing performance (ES default : 200MB)
default.elasticsearch[:index][:translog][:flush_threshold_size] = "1GB"

  # for using Kibana
default.elasticsearch[:http][:cors][:enabled] = true

# === OTHER SETTINGS
#
default.elasticsearch[:skip_restart] = false
default.elasticsearch[:skip_start] = false

# === PORT
#
default.elasticsearch[:http][:port] = 9200

# === CUSTOM CONFIGURATION
#
default.elasticsearch[:custom_config] = {}

# === LOGGING
#
# See `attributes/logging.rb`
#
default.elasticsearch[:logging] = {}

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
# to set other configurations, set the `node.elasticsearch[:custom_config]` attribute in the
# node configuration, `elasticsearch/settings` data bag, role/environment definition, etc:
#
#     // ...
#     'threadpool.index.type' => 'fixed',
#     'threadpool.index.size' => '2'
#     // ...
#
