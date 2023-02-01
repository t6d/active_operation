require "bundler/gem_tasks"
require "rspec/core/rake_task"

rspec = RSpec::Core::RakeTask.new(:spec)
rspec.ruby_opts = "-w"

task :default => :spec
