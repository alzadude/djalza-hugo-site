#!/bin/sh

# This script is based on the following non-worktree example script 
# in order to avoid 'Refusing to point HEAD outside of refs/' error with git 2.7.4: 
# https://discourse.gohugo.io/t/github-deployment-using-worktrees-failing/5918/5

set -e

DIR=$(dirname "$0")

cd $DIR/..

if [ -n "$(git status -s -uno)"  ]
then
    echo "The working directory is dirty. Please commit any pending changes."
    exit 1;
fi

SHA=$(git rev-parse HEAD)
if [ -n "$GITHUB_API_TOKEN" ]; then
    GIT_USER_ARGS="-c user.name='travis' -c user.email='travis'"
fi

echo "Deleting old publication"
rm -rf public
mkdir public

echo "Creating gh-pages branch in ./public"
git -C public init
git -C public checkout -b gh-pages

echo "Generating site"
hugo

echo "Updating gh-pages branch"
git -C public add --all
git -C public $GIT_USER_ARGS commit -m "Publishing to gh-pages ($SHA)"

echo "Pushing gh-pages branch"
if [ -n "$GITHUB_API_TOKEN" ]; then
    # CI deployment
    git -C public push -f https://alzadude:$GITHUB_API_TOKEN@github.com/alzadude/djalza-hugo-site gh-pages:gh-pages 2>&1 | \
        sed s/$GITHUB_API_TOKEN/HIDDEN/g
else
    # Manual deployment
    git -C public push -f https://github.com/alzadude/djalza-hugo-site gh-pages
fi