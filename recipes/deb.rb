# See <http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/_linux.html>

filename = node.elasticsearch2[:deb_url].split('/').last

remote_file "#{Chef::Config[:file_cache_path]}/#{filename}" do
  source   node.elasticsearch2[:deb_url]
  checksum node.elasticsearch2[:deb_sha]
  mode 00644
end

dpkg_package "#{Chef::Config[:file_cache_path]}/#{filename}" do
  action :install
end

ruby_block "Set heap size in /etc/default/elasticsearch" do
  block do
    fe = Chef::Util::FileEdit.new("/etc/default/elasticsearch")
    fe.insert_line_if_no_match(/ES_HEAP_SIZE=/, "ES_HEAP_SIZE=#{node.elasticsearch2[:allocated_memory]}")
    fe.search_file_replace_line(/ES_HEAP_SIZE=/, "ES_HEAP_SIZE=#{node.elasticsearch2[:allocated_memory]}") # if the value has changed but the line exists in the file
    fe.write_file
  end
end
