#!/bin/bash

set -e

hg id | grep + > /dev/null && { echo "Uncommitted changes found. Commit things first!"; exit; }

rm -f *.gem

gem build iop.gemspec

for gem in *.gem; do
  gem push $gem
done

hg tag "iop-`ruby -e 'puts Gem::Specification.load(%~iop.gemspec~).version'`-release"

hg push

#