# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "siba-source-mysql/version"

Gem::Specification.new do |s|
  s.name        = "siba-source-mysql"
  s.version     = Siba::Source::Mysql::VERSION
  s.authors     = ["Evgeny Neumerzhitskiy"]
  s.email       = ["sausageskin@gmail.com"]
  s.homepage    = ""
  s.license     = "MIT"
  s.summary     = %q{MySQL backup and restore extention for SIBA utility}
  s.description = %q{An extension for SIBA utility. It allows to backup and restore MySQL database.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency     'siba', '~>0.5'

  s.add_development_dependency  'minitest', '~>2.10'
  s.add_development_dependency  'rake', '~>0.9'
  s.add_development_dependency  'guard-minitest', '~>0.4'
end
