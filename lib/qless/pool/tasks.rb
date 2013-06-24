# -*- encoding: utf-8 -*-
require 'qless/tasks'

namespace :qless do

  # qless worker config (not pool related).  e.g. hoptoad, rails environment
  task :setup

  namespace :pool do
     # qless pool config.  e.g. after_prefork connection handling
    task :setup
  end

  desc "Launch a pool of qless workers"
  task :pool => %w[qless:setup qless:pool:setup] do
    require 'qless/pool'
    Qless::Pool.run
  end

end
