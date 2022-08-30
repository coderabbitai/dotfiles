#!/usr/bin/env bash

# accept only 1 argument
if [ $# -ne 1 ]; then
	echo "Usage: $0 <base_directory_that_contains_repos>"
	exit 1
fi

echo "Pulling..."

# iterate directories contained within the directory provided in the first argument in parallel and cd into each to run git pull
parallel --no-notice --bar --eta --colsep '\n' "cd {} && git pull --quiet --rebase" ::: "$(find "$1" -maxdepth 1 -mindepth 1 -type d)"
code=$?

echo "Finished pull"

exit $code
