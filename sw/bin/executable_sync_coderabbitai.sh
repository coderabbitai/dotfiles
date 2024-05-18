#!/usr/bin/env bash

gh_clone_all.sh coderabbitai ~/Work
pull_all.sh ~/Work/coderabbitai

# go through all the directories in ~/Work/coderabbitai
# look for package.json files in the subdirectories
# and run pnpm install in those directories
find ~/Work/coderabbitai -depth 2 -name package.json -exec dirname {} \; | while read dir; do
	# if the directory contains a pnpm-lock.yaml file use pnpm
	# otherwise look for a yarn.lock file and use yarn
	# otherwise look for a package-lock.json file and use npm
	if [ -f "$dir/pnpm-lock.yaml" ]; then
		echo "Running pnpm install in $dir"
		(cd $dir && pnpm install)
	elif [ -f "$dir/yarn.lock" ]; then
		echo "Running yarn install in $dir"
		(cd $dir && yarn install)
	elif [ -f "$dir/package-lock.json" ]; then
		echo "Running npm install in $dir"
		(cd $dir && npm install)
	fi
done
