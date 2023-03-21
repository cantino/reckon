#!/bin/bash

set -e

VERSION=$1

if [ -z "$TOKEN" ]; then
    echo "\$TOKEN var must be your github api token"
    exit 1
fi

echo "Install github_changelog_generator"
gem install --user github_changelog_generator

echo "Update 'lib/reckon/version.rb'"
echo -e "module Reckon\n  VERSION = \"$VERSION\"\nend" > lib/reckon/version.rb
echo "Run `bundle install` to build updated Gemfile.lock"
bundle install
echo "Run changelog generator (requires $TOKEN to be your github token)"
github_changelog_generator -u cantino -p reckon -t "$TOKEN" --future-release "v$VERSION"
echo "Commit changes"
git add CHANGELOG.md lib/reckon/version.rb Gemfile.lock
git commit -m "Release $VERSION"
echo "Tag release"
git tag "v$VERSION"
echo "Build new gem"
gem build reckon.gemspec
echo "Push changes and tags"
echo "git push && git push --tags"
echo "Push new gem"
echo "gem push reckon-$VERSION.gem"
gh release create "v$VERSION" "reckon-$VERSION.gem" --draft --generate-notes
