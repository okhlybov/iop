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
  spec.files = Dir.glob ['lib/**/*.rb', 'test/**/*.rb', '.yardopts', '*.ad']
  spec.required_ruby_version = '>= 2.3'
  spec.licenses = ['BSD-3-Clause']
  spec.description = <<-EOF
    I/O pipeline construction framework.
    Allows to construct data and file processing pipelines in a manner of UNIX shell pipes.
    Implemented features:
    - String splitting/merging
    - IO or local file reading/writing
    - FTP file reading/writing
    - Digest computing
    - GZip/Zlib (de)compression
    - Zstd (de)compression
    - Symmetric cipher (de,en)cryption
    - Random data generation
  EOF
end