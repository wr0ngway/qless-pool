Qless Pool
===========

[![Build Status](https://secure.travis-ci.org/backupify/qless-pool.png)](http://travis-ci.org/backupify/qless-pool)
[![Dependency Status](https://gemnasium.com/backupify/qless-pool.png)](https://gemnasium.com/backupify/qless-pool)

Qless pool is a simple library for managing a pool of
[qless](http://github.com/seomoz/qless) workers.  Given a a config file, it
manages your workers for you, starting up the appropriate number of workers for
each worker type.  This is a fork of [resque-pool](https://github.com/nevans/resque-pool) with some commits from a [backupify fork of it](https://github.com/backupify/resque-pool/tree/maintain_count)

Benefits
---------

* Less config - With a simple YAML file, you can start up a pool daemon, and it
  will monitor your workers for you.  An example init.d script, monit config,
  and chef cookbook are provided.
* Less memory - If you are using Ruby Enterprise Edition, or any ruby with
  copy-on-write safe garbage collection, this should save you a *lot* of memory
  when you are managing many workers.
* Faster startup - when you start many workers at once, they would normally
  compete for CPU as they load their environments.  Qless-pool can load the
  environment once and fork all of the workers almost instantly.

Upgrading?
-----------

See
[Changelog.md](https://github.com/backupify/qless-pool/blob/master/Changelog.md)
in case there are important or helpful changes.

How to use
-----------

### YAML file config

Create a `config/qless-pool.yml` (or `qless-pool.yml`) with your worker
counts.  The YAML file supports both using root level defaults as well as
environment specific overrides (`RACK_ENV`, `RAILS_ENV`, and `QLESS_ENV`
environment variables can be used to determine environment).  For example in
`config/qless-pool.yml`:

    foo: 1
    bar: 2
    "foo,bar,baz": 1

    production:
      "foo,bar,baz": 4

### Rake task config

Require the rake tasks (`qless/pool/tasks`) in your `Rakefile`, load your
application environment, configure Qless as necessary, and configure
`qless:pool:setup` to disconnect all open files and sockets in the pool
manager and reconnect in the workers.  For example, with rails you should put
the following into `lib/tasks/qless.rake`:

    require 'qless/pool/tasks'
    # this task will get called before qless:pool:setup
    # and preload the rails environment in the pool manager
    task "qless:setup" => :environment do
      # generic worker setup, e.g. Hoptoad for failed jobs
    end
    task "qless:pool:setup" do
      # close any sockets or files in pool manager
      ActiveRecord::Base.connection.disconnect!
      # and re-open them in the qless worker parent
      Qless::Pool.after_prefork do |job|
        ActiveRecord::Base.establish_connection
      end
    end

### Start the pool manager

Then you can start the queues via:

    qless-pool --daemon --environment production

This will start up seven worker processes, one exclusively for the foo queue,
two exclusively for the bar queue, and four workers looking at all queues in
priority.  With the config above, this is similar to if you ran the following:

    rake qless:work RAILS_ENV=production QUEUES=foo &
    rake qless:work RAILS_ENV=production QUEUES=bar &
    rake qless:work RAILS_ENV=production QUEUES=bar &
    rake qless:work RAILS_ENV=production QUEUES=foo,bar,baz &
    rake qless:work RAILS_ENV=production QUEUES=foo,bar,baz &
    rake qless:work RAILS_ENV=production QUEUES=foo,bar,baz &
    rake qless:work RAILS_ENV=production QUEUES=foo,bar,baz &

The pool manager will stay around monitoring the qless worker parents, giving
three levels: a single pool manager, many worker parents, and one worker child
per worker (when the actual job is being processed).  For example, `ps -ef f |
grep [r]esque` (in Linux) might return something like the following:

    qless    13858     1  0 13:44 ?        S      0:02 qless-pool-manager: managing [13867, 13875, 13871, 13872, 13868, 13870, 13876]
    qless    13867 13858  0 13:44 ?        S      0:00  \_ qless-1.9.9: Waiting for foo
    qless    13868 13858  0 13:44 ?        S      0:00  \_ qless-1.9.9: Waiting for bar
    qless    13870 13858  0 13:44 ?        S      0:00  \_ qless-1.9.9: Waiting for bar
    qless    13871 13858  0 13:44 ?        S      0:00  \_ qless-1.9.9: Waiting for foo,bar,baz
    qless    13872 13858  0 13:44 ?        S      0:00  \_ qless-1.9.9: Forked 7481 at 1280343254
    qless     7481 13872  0 14:54 ?        S      0:00      \_ qless-1.9.9: Processing foo since 1280343254
    qless    13875 13858  0 13:44 ?        S      0:00  \_ qless-1.9.9: Waiting for foo,bar,baz
    qless    13876 13858  0 13:44 ?        S      0:00  \_ qless-1.9.9: Forked 7485 at 1280343255
    qless     7485 13876  0 14:54 ?        S      0:00      \_ qless-1.9.9: Processing bar since 1280343254

Running as a daemon will default to placing the pidfile and logfiles in the
conventional rails locations, although you can configure that.  See
`qless-pool --help` for more options.

SIGNALS
-------

The pool manager responds to the following signals:

* `HUP`   - reload the config file, reload logfiles, restart all workers.
* `QUIT`  - gracefully shut down workers (via `QUIT`) and shutdown the manager
  after all workers are done.
* `INT`   - gracefully shut down workers (via `QUIT`) and immediately shutdown manager
* `TERM`  - immediately shut down workers (via `INT`) and immediately shutdown manager
  _(configurable via command line options)_
* `WINCH` - _(only when running as a daemon)_ send `QUIT` to each worker, but
  keep manager running (send `HUP` to reload config and restart workers)
* `USR1`/`USR2`/`CONT` - pass the signal on to all worker parents (see Qless docs).

Use `HUP` to help logrotate run smoothly and to change the number of workers
per worker type.  Signals can be sent via the `kill` command, e.g.
`kill -HUP $master_pid`

Other Features
--------------

An example chef cookbook is provided (and should Just Work at Engine Yard as
is; just provide a `/data/#{app_name}/shared/config/qless-pool.yml` on your
utility instances).  Even if you don't use chef you can use the example init.d
and monitrc erb templates in `examples/chef_cookbook/templates/default`.

You can also start a pool manager via `rake qless:pool` or from a plain old
ruby script by calling `Qless::Pool.run`.

Workers will watch the pool manager, and gracefully shutdown (after completing
their current job) if the manager process disappears before them.

You can specify an alternate config file by setting the `QLESS_POOL_CONFIG` or
with the `--config` command line option.

TODO
-----

See [the TODO list](https://github.com/backupify/qless-pool/issues) at github issues.

Contributors
-------------

* Nicholas Evans (Author of resque-pool which this is a fork of)
* Jason Haruska (from resque-pool)
* John Schult (from resque-pool)
* Stephen Celis (from resque-pool)
* Vincent Agnello, Robert Kamunyori, Paul Kauders (from resque-pool)

