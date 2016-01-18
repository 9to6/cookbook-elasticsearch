directory "#{node.elasticsearch2[:dir]}/elasticsearch-#{node.elasticsearch2[:version]}/plugins/" do
  owner node.elasticsearch2[:user]
  group node.elasticsearch2[:user]
  mode 0755
  recursive true
end

node[:elasticsearch2][:plugins].each do | name, config |
  next if name == 'elasticsearch/elasticsearch-cloud-aws' && !node.recipe?('aws')
  next if name == 'elasticsearch/elasticsearch-cloud-gce' && !node.recipe?('gce')
  install_plugin name, config
end
