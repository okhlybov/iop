# IOP - the data processing pipeline construction framework for Ruby

## Synopsis

IOP is intended for constructing the data processing pipelines in a manner of UNIX command-line pipes.

Instead of the standard Ruby way of handling such I/O tasks in form of nested blocks the IOP offers a more simple flat chaining scheme.

Consider the example:
```ruby
# One-liner example
(FileReader.new('input.dat') | GzipCompressor.new | DigestComputer.new(MD5.new) | FileWriter.new('output.dat.gz')).process!
```

The above code snippet reads input file and compresses it into the GZip-compatible output file simultaneously computing the MD5 hash of compressed data being written.

The next code snippet presents the incremental pipeline construction capability - a feature not easily implementable with the standard Ruby I/O blocks nesting.

```ruby
# Incremental pipeline construction example
pipe  = FileReader.new('input')
pipe |= GzipCompressor.new if need_compression?
pipe |= FileWriter.new('output')
pipe.process!
```

Here the GZip compression is made optional and is thrown in depending on external condition. 