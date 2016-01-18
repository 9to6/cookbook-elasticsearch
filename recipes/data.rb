node.elasticsearch2[:data][:devices].each do |device, params|
  # Format volume if format command is provided and volume is unformatted
  #
  bash "Format device: #{device}" do
    __command  = "#{params[:format_command]} #{device}"
    __fs_check = params[:fs_check_command] || 'dumpe2fs'

    code __command

    only_if { params[:format_command] }
    not_if  "#{__fs_check} #{device}"
  end

  # Create directory with proper permissions
  #
  directory params[:mount_path] do
    owner node.elasticsearch2[:user] and group node.elasticsearch2[:user] and mode 0755
    recursive true
  end

  # Mount device to elasticsearch data path
  #
  mount "#{device}-to-#{params[:mount_path]}" do
    mount_point params[:mount_path]
    device  device
    fstype  params[:file_system]
    options params[:mount_options]
    action  [:mount, :enable]

    only_if { File.exists?(device) }
    if node.elasticsearch2[:path][:data].include?(params[:mount_path])
      Chef::Log.debug "Schedule Elasticsearch service restart..."
      notifies :restart, 'service[elasticsearch]' unless node.elasticsearch2[:skip_restart]
    end
  end

  # Ensure proper permissions
  #
  directory params[:mount_path] do
    owner node.elasticsearch2[:user] and group node.elasticsearch2[:user] and mode 0755
    recursive true
  end
end
