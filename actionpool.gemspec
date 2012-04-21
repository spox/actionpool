spec = Gem::Specification.new do |s|
  s.name        = 'actionpool'
  s.author      = %q(spox)
  s.email       = %q(spox@modspox.com)
  s.version       = '0.2.3'
  s.summary       = %q(Thread Pool)
  s.platform      = Gem::Platform::RUBY
  s.files       = Dir['**/*']
  s.rdoc_options    = %w(--title ActionPool --main README.rdoc --line-numbers)
  s.extra_rdoc_files  = %w(README.rdoc CHANGELOG)
  s.require_paths   = %w(lib)
  s.required_ruby_version = '>= 1.8.6'
  s.add_dependency  'splib', '~> 1.4'
  s.homepage      = %q(http://github.com/spox/actionpool)
  s.description     = "The ActionPool is an easy to use thread pool for ruby."
end
