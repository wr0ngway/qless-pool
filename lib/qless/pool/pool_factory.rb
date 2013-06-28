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

      def reserver(queues)
        reserver_class.new(queues)
      end
      
      def worker(queues)
        queues = queues.to_s.split(',').map { |q| client.queues[q.strip] }
        if queues.none?
          raise "No queues provided"
        end
  
        Qless::Worker.new(reserver(queues), @options)
      end
            
    end
end
