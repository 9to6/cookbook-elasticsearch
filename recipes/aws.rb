node.default[:elasticsearch2][:plugin][:mandatory] = Array(node[:elasticsearch2][:plugin][:mandatory] | ['cloud-aws'])

install_plugin "elasticsearch/elasticsearch-cloud-aws/#{node.elasticsearch2['plugins']['elasticsearch/elasticsearch-cloud-aws']['version']}"
