spec = Gem::Specification.new do |s|
    s.name              = 'ActionPool'
    s.author            = %q(spox)
    s.email             = %q(spox@modspox.com)
    s.version           = '0.0.1'
    s.summary           = %q(Thread Pool)
    s.platform          = Gem::Platform::RUBY
    s.has_rdoc          = true
    s.files             = Dir['**/*']
    s.require_paths     = %w(lib)
    s.required_ruby_version = '>= 1.8.6'
end