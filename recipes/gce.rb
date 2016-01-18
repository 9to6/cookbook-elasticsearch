node.default[:elasticsearch2][:plugin][:mandatory] = Array(node[:elasticsearch2][:plugin][:mandatory] | ['cloud-gce'])

install_plugin "elasticsearch/elasticsearch-cloud-gce/#{node.elasticsearch2['plugins']['elasticsearch/elasticsearch-cloud-gce']['version']}"
