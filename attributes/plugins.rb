Chef::Log.debug "Attempting to load plugin list from the databag..."

plugins = Chef::DataBagItem.load('elasticsearch2', 'plugins')[node.chef_environment].to_hash['plugins'] rescue {}

node.default.elasticsearch2[:plugins].merge!(plugins)
node.default.elasticsearch2[:plugin][:mandatory] = []

Chef::Log.debug "Plugins list: #{default.elasticsearch2.plugins.inspect}"
