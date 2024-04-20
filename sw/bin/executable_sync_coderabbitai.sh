#!/usr/bin/env bash

gh_clone_all.sh coderabbitai ~/Work
pull_all.sh ~/Work/coderabbitai

# go through all the directories in ~/Work/coderabbitai
# look for package.json files in the subdirectories
# and run pnpm install in those directories
find ~/Work/coderabbitai -name package.json -exec dirname {} \; | while read dir; do
	echo "Installing dependencies in $dir"
	(cd $dir && pnpm install)
done
