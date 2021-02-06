#!/bin/bash

set -e

VERSION=$1

echo "Install github_changelog_generator"
gem install --user github_changelog_generator

echo "Update 'lib/reckon/version.rb'"
echo -e "module Reckon\n  VERSION=\"$VERSION\"\nend" > lib/reckon/version.rb
echo "Run `bundle install` to build updated Gemfile.lock"
bundle install
echo "3. Run changelog generator (requires $TOKEN to be your github token)"
github_changelog_generator -u cantino -p reckon -t $TOKEN --future-release $VERSION
echo "4. Commit changes"
git add CHANGELOG.md lib/reckon/version.rb Gemfile.lock
git commit -m "Release $VERSION"
echo "7. Build new gem"
gem build reckon.gemspec
echo "5. Tag release"
git tag v$VERSION
echo "Push changes and tags"
git push && git push --tags
echo "Push new gem"
gem push reckon-$VERSION.gem
