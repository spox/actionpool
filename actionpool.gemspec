spec = Gem::Specification.new do |s|
    s.name              = 'ActionPool'
    s.author            = %q(spox)
    s.email             = %q(spox@modspox.com)
    s.version           = '0.2.1'
    s.summary           = %q(Thread Pool)
    s.platform          = Gem::Platform::RUBY
    s.files             = Dir['**/*']
    s.rdoc_options      = %w(--title ActionPool --main README.rdoc --line-numbers)
    s.extra_rdoc_files  = %w(README.rdoc CHANGELOG)
    s.require_paths     = %w(lib)
    s.required_ruby_version = '>= 1.8.6'
    s.homepage          = %q(http://github.com/spox/actionpool)
    description         = []
    File.open("README.rdoc") do |file|
        file.each do |line|
            line.chomp!
            break if line.empty?
            description << "#{line.gsub(/\[\d\]/, '')}"
        end
    end
    s.description = description[1..-1].join(" ")
end
