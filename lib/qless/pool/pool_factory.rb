require 'qless/job_reservers/ordered'
require 'qless/worker'

module Qless
    class PoolFactory

      def initialize(options={})
        @options = {
            :term_timeout => ENV['TERM_TIMEOUT'] || 4.0,
            :verbose => !!ENV['VERBOSE'],
            :very_verbose => !!ENV['VVERBOSE'],
           :run_as_single_process => !!ENV['RUN_AS_SINGLE_PROCESS']
        }.merge(options)
      end
      
      def client
        @qless_client ||= Qless::Client.new
      end
      
      def client=(client)
        @qless_client = client
      end
          
      def reserver_class
        @reserver_class ||= Qless::JobReservers.const_get(ENV.fetch('JOB_RESERVER', 'Ordered'))
      end
      
      def reserver_class=(reserver_class)
        @reserver_class = reserver_class
      end

      def worker_class
        @worker_class ||= begin
          if defined?(Qless::Workers::ForkingWorker)
            Qless::Workers::ForkingWorker
          else
            Qless::Worker
          end
        end
      end

      def worker_class=(worker_class)
        @worker_class = worker_class
      end

      def reserver(queues)
        reserver_class.new(queues)
      end
      
      def worker(queues)
        queues = queues.to_s.split(',').map { |q| client.queues[q.strip] }
        if queues.none?
          raise "No queues provided"
        end
  
        worker_class.new(reserver(queues), @options)
      end
            
    end
end
