# IOP - the data processing pipeline construction framework for Ruby

## Synopsis

IOP is intended for constructing the data processing pipelines in a manner of UNIX command-line pipes.

Instead of the standard Ruby way of handling such I/O tasks in form of nested blocks the IOP offers a simpler flat chaining scheme.

Consider the example:

```ruby
# One-liner example
(FileReader.new('input.dat') | GzipCompressor.new | DigestComputer.new(MD5.new) | FileWriter.new('output.dat.gz')).process!
```

The above snippet reads input file and compresses it into the GZip-compatible output file simultaneously computing the MD5 hash of compressed data being written.

The next snippet presents the incremental pipeline construction capability - a feature not easily implementable with the standard Ruby I/O blocks nesting.

```ruby
# Incremental pipeline construction example
pipe  = FileReader.new('input')
pipe |= GzipCompressor.new if need_compression?
pipe |= FileWriter.new('output')
pipe.process!
```

Here the GZip compression is made optional and is thrown in depending on external condition.

## Features

The following capabilities are currently implemented:

- String splitting/merging
- IO or local file reading/writing
- FTP file reading/writing
- Digest computing
- GZip/Zlib (de)compression
- Symmetric cipher (de,en)cryption

## Basic usage

- IOP is split into a set of files which should be required separately depending on which components are needed.

```ruby
require 'iop/file'
require 'iop/zlib'
require 'iop/digest'
require 'iop/string'
```

- The {IOP} module can be included into current namespace to conserve some writing.

```ruby
include IOP
```

- A chain of processing objects is created either in-line or incrementally.

```ruby
pipe  = StringSplitter.new('Greetings from IOP', 10)
pipe |= GzipCompressor.new | (digest = DigestComputer.new(MD5.new))
pipe |= FileWriter.new('output.gz')
```

It is convenient to set local variables to the created instances which are expected to have some kind of valuable state.

- The actual processing is initiated with the `process!` method.

```ruby
pipe.process!
```

The IOP instances do normally perform self-cleanup operations, such as closing file handles, network connections etc., even during exception handling.

- The variable-bound instances can be then examined.

```ruby
puts digest.hexdigest
```
