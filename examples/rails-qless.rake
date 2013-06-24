require 'qless/pool/tasks'

# this task will get called before qless:pool:setup
# preload the rails environment in the pool master
task "qless:setup" => :environment do
  # generic worker setup, e.g. Hoptoad for failed jobs
end

task "qless:pool:setup" do
  # close any sockets or files in pool master
  ActiveRecord::Base.connection.disconnect!

  # and re-open them in the qless worker parent
  Qless::Pool.after_prefork do |job|
    ActiveRecord::Base.establish_connection
  end

  # you could also re-open them in the qless worker child, using
  # Qless.after_fork, but that probably isn't necessary, and
  # Qless::Pool.after_prefork should be faster, since it won't run
  # for every single job.
end
