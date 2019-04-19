$:.unshift 'lib'

require 'iop'

Gem::Specification.new do |spec|
  spec.name = 'iop'
  spec.version = IOP::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.author = ['Oleg A. Khlybov']
  spec.email = ['fougas@mail.ru']
  spec.homepage = 'https://bitbucket.org/fougas/iop'
  spec.summary = 'I/O pipeline construction framework'
  spec.files = Dir.glob ['lib/**/*.rb', 'test/**/*.rb', '.yardopts', '*.md']
  spec.required_ruby_version = '>= 2.3'
  spec.licenses = ['BSD-3-Clause']
  spec.description = <<-EOF
    I/O pipeline construction framework.
    Allows to construct data processing pipelines in a manner of UNIX shell pipes.
    Implemented features:
      string splitting/merging,
      IO or local file reading/writing,
      FTP file reading/writing,
      digest computing,
      Gzip/Zlib (de)compression,
      Zstd (de)compression,
      symmetric cipher (de,en)cryption,
      random data generation.
  EOF
end