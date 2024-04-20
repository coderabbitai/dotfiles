#!/usr/bin/env bash

gh_clone_all.sh coderabbitai ~/Work
pull_all.sh ~/Work/coderabbitai

# go through all the directories in ~/Work/coderabbitai
# look for package.json files in the subdirectories
for dir in ~/Work/coderabbitai/*; do
	if [ -d "$dir" ]; then
		# find all package.json files in the subdirectories
		package_json_files=$(find "$dir" -name package.json)
		for package_json_file in $package_json_files; do
			# run pnpm install in the directory containing the package.json file
			pushd "$(dirname "$package_json_file")" >/dev/null || continue
			pnpm install
			popd >/dev/null || continue
		done
	fi
done
