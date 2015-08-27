Gem::Specification.new do |s|
  s.name        = 'clide'
  s.version     = '0.1.0'
  s.date        = '2015-08-23'
  s.summary     = "Command Line IDE"
  s.description = "A set of tools to offer modern IDE functionality from the command line"
  s.authors     = ["Michael Brailsford"]
  s.email       = 'brailsmt@yahoo.com'
  s.files       = Dir['lib/**']
  s.homepage    = 'http://www.github.com/brailsmt/clide'
  s.license     = 'MIT'
  s.executables << 'clide'
  s.add_runtime_dependency 'parseconfig'
end
