$: << 'lib'

require 'iop'

Gem::Specification.new do |spec|
  spec.name = 'iop'
  spec.version = IOP::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.author = ['Oleg A. Khlybov']
  spec.email = ['fougas@mail.ru']
  spec.homepage = 'https://bitbucket.org/fougas/iop'
  spec.summary = 'I/O pipeline construction framework'
  spec.files = Dir.glob ['lib/**/*.rb']
  spec.required_ruby_version = '>= 2.3'
  spec.licenses = ['BSD-3-Clause']
  spec.description = <<-EOF
    Allows to construct data and file processing pipelines in a UNIX-like way.
  EOF
end