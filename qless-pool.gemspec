# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qless/pool/version"

Gem::Specification.new do |s|
  s.name        = "qless-pool"
  s.version     = Qless::Pool::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matt Conway", "Nicholas a. Evans"]
  s.email       = ["matt@conwaysplace.com", "nick@ekenosen.net"]
  s.homepage    = "http://github.com/backupify/qless-pool"
  s.summary     = "quickly and easily fork a pool of qless workers"
  s.description = <<-EOF
    quickly and easily fork a pool of qless workers,
    saving memory (w/REE) and monitoring their uptime
  EOF

  s.add_dependency "qless",  "~> 0.9"
  s.add_dependency "trollop", "~> 1.16"
  s.add_dependency "rake"
  s.add_development_dependency "rspec",    "~> 2.10.0"
  s.add_development_dependency "cucumber", "~> 1.2.0"
  s.add_development_dependency "aruba",    "~> 0.4.11"
  s.add_development_dependency "bundler", "~> 1.0"
  s.add_development_dependency "ronn"

  # only in ruby 1.8
  s.add_development_dependency "SystemTimer" if RUBY_VERSION =~ /^1\.8/

  s.files         = %w( README.md Rakefile LICENSE.txt CHANGELOG)
  s.files         += Dir.glob("lib/**/*")
  s.files         += Dir.glob("bin/**/*")
  s.files         += Dir.glob("man/**/*")
  s.files         += Dir.glob("features/**/*")
  s.files         += Dir.glob("spec/**/*")
  s.test_files    = Dir.glob("{spec,features}/**/*.{rb,yml,feature}")
  s.executables   = 'qless-pool'
  s.require_paths = ["lib"]
end
