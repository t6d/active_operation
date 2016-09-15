# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_operation/version'

Gem::Specification.new do |spec|
  spec.name          = "active_operation"
  spec.version       = ActiveOperation::VERSION
  spec.authors       = ["Konstantin Tennhard", "Sebastian Szturo"]
  spec.email         = ["konstantin@tennhard.net", "sebastian.szturo@gmail.com"]

  spec.summary       = %q{ActiveOperation is a micro-framework for modelling business processes.}
  spec.homepage      = "https://gitub.com/t6d/active_operation"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", "> 4.0"
  spec.add_runtime_dependency "smart_properties", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
