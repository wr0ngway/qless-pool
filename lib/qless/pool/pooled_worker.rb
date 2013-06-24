require 'qless/worker'

class Qless::Pool
  module PooledWorker
    def shutdown_with_pool
      shutdown_without_pool || Process.ppid == 1
    end

    def self.included(base)
      base.instance_eval do
        alias_method :shutdown_without_pool, :shutdown?
        alias_method :shutdown?, :shutdown_with_pool
      end
    end

  end
end

Qless::Worker.class_eval do
  include Qless::Pool::PooledWorker
end
