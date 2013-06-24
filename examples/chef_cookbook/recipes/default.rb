roles = %w[solo util]
if roles.include?(node[:instance_role])
  node[:applications].each do |app, data|

    pidfile = "/data/#{app}/current/tmp/pids/#{app}_qless.pid"

    template "/etc/monit.d/#{app}_qless.monitrc" do
      owner 'root'
      group 'root'
      mode 0644
      source "monitrc.erb"
      variables({
        :app_name => app,
        :pidfile  => pidfile,
        #:max_mem  => "400 MB",
      })
    end

    template "/etc/init.d/#{app}_qless" do
      owner 'root'
      group 'root'
      mode 0744
      source "initd.erb"
      variables({
        :app_name => app,
        :pidfile  => pidfile,
      })
    end

    execute "enable-qless" do
      command "rc-update add #{app}_qless default"
      action :run
      not_if "rc-update show | grep -q '^ *#{app}_qless |.*default'"
    end

    execute "start-qless" do
      command %Q{/etc/init.d/#{app}_qless start}
      creates pidfile
    end

    execute "ensure-qless-is-setup-with-monit" do
      command %Q{monit reload}
    end

  end
end
