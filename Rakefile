require 'rubygems'
require 'rake/gempackagetask'
require 'spec/rake/spectask'

NAME = 'sequel_sti_nested_set'
VERS = '0.0.1'

desc 'Package sequel_sti_nested_set'
spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = VERS
  s.platform = Gem::Platform::RUBY
  s.summary = "Sequel_StiNestedSet"
  s.description = s.summary
  s.author = "Jun Kikuchi"
  s.email = "kikuchi@bonnou.com"
  s.homepage = "http://bonnou.com/"
  s.files = %w(COPYING CHANGELOG README.rdoc Rakefile) + Dir.glob("{bin,doc,spec,lib}/**/*")
  s.require_path = "lib"
  s.has_rdoc = true
end

Rake::GemPackageTask.new(spec) do |pkg|
end

Spec::Rake::SpecTask.new do |t|
  #t.spec_opts = ['-c --format specdoc']
  t.spec_opts = ['-c']
  t.spec_files = FileList['spec/**/*_spec.rb']
end
