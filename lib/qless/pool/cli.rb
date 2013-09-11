require 'trollop'
require 'qless/pool'
require 'fileutils'

module Qless
  class Pool
    module CLI
      extend self

      def run
        opts = parse_options
        daemonize if opts[:daemon]
        manage_pidfile opts[:pidfile]
        redirect opts
        setup_environment opts
        set_pool_options opts
        start_pool
      end

      def parse_options
        opts = Trollop::options do
          version "qless-pool #{VERSION} (c) nicholas a. evans"
          banner <<-EOS
qless-pool is the best way to manage a group (pool) of qless workers

When daemonized, stdout and stderr default to qless-pool.stdxxx.log files in
the log directory and pidfile defaults to qless-pool.pid in the current dir.

Usage:
   qless-pool [options]
where [options] are:
          EOS
          opt :config, "Alternate path to config file", :type => String, :short => "-c"
          opt :appname, "Alternate appname",         :type => String,    :short => "-a"
          opt :daemon, "Run as a background daemon", :default => false,  :short => "-d"
          opt :stdout, "Redirect stdout to logfile", :type => String,    :short => '-o'
          opt :stderr, "Redirect stderr to logfile", :type => String,    :short => '-e'
          opt :nosync, "Don't sync logfiles on every write"
          opt :pidfile, "PID file location",         :type => String,    :short => "-p"
          opt :environment, "Set RAILS_ENV/RACK_ENV/QLESS_ENV", :type => String, :short => "-E"
          opt :term_graceful_wait, "On TERM signal, wait for workers to shut down gracefully"
          opt :term_graceful,      "On TERM signal, shut down workers gracefully"
          opt :term_immediate,     "On TERM signal, shut down workers immediately (default)"
        end
        if opts[:daemon]
          opts[:stdout]  ||= "log/qless-pool.stdout.log"
          opts[:stderr]  ||= "log/qless-pool.stderr.log"
          opts[:pidfile] ||= "tmp/pids/qless-pool.pid"
        end
        opts
      end

      def daemonize
        raise 'First fork failed' if (pid = fork) == -1
        exit unless pid.nil?
        Process.setsid
        raise 'Second fork failed' if (pid = fork) == -1
        exit unless pid.nil?
      end

      def manage_pidfile(pidfile)
        return unless pidfile
        pid = Process.pid
        if File.exist? pidfile
          if process_still_running? pidfile
            raise "Pidfile already exists at #{pidfile} and process is still running."
          else
            File.delete pidfile
          end
        else
          FileUtils.mkdir_p File.dirname(pidfile)
        end
        File.open pidfile, "w" do |f|
          f.write pid
        end
        at_exit do
          if Process.pid == pid
            File.delete pidfile
          end
        end
      end

      def process_still_running?(pidfile)
        old_pid = open(pidfile).read.strip.to_i
        Process.kill 0, old_pid
        true
      rescue Errno::ESRCH
        false
      rescue Errno::EPERM
        true
      rescue ::Exception => e
        $stderr.puts "While checking if PID #{old_pid} is running, unexpected #{e.class}: #{e}"
        true
      end

      def redirect(opts)
        $stdin.reopen  '/dev/null'        if opts[:daemon]
        # need to reopen as File, or else Qless::Pool::Logging.reopen_logs! won't work
        out = File.new(opts[:stdout], "a") if opts[:stdout] && !opts[:stdout].empty?
        err = File.new(opts[:stderr], "a") if opts[:stderr] && !opts[:stderr].empty?
        $stdout.reopen out if out
        $stderr.reopen err if err
        $stdout.sync = $stderr.sync = true unless opts[:nosync]
      end

      # TODO: global variables are not the best way
      def set_pool_options(opts)
        if opts[:daemon]
          Qless::Pool.handle_winch = true
        end
        if opts[:term_graceful_wait]
          Qless::Pool.term_behavior = "graceful_worker_shutdown_and_wait"
        elsif opts[:term_graceful]
          Qless::Pool.term_behavior = "graceful_worker_shutdown"
        end
      end

      def setup_environment(opts)
        Qless::Pool.app_name = opts[:appname]    if opts[:appname]
        ENV["RAILS_ENV"] ||= 'development'
        ENV["RACK_ENV"] = ENV["RAILS_ENV"] = ENV["QLESS_ENV"] = opts[:environment] if opts[:environment]
        Qless::Pool.log "Qless Pool running in #{ENV["RAILS_ENV"]} environment"
        ENV["QLESS_POOL_CONFIG"] = opts[:config] if opts[:config]
      end

      def start_pool
        require 'rake'
        require 'qless/pool/tasks'
        Rake.application.init
        Rake.application.load_rakefile
        Rake.application["qless:pool"].invoke
      end

    end
  end
end

