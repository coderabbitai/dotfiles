#!/usr/bin/env bash

# Accept 2 arguments
if [ $# -ne 2 ]; then
	echo "Usage: $0 <github_org> <base_dir>"
	exit 1
fi

echo "Cloning..."

tput civis
revolver --style 'dots2' start "Fetching $1 repos list from GitHub..."
repolist=$(gh repo list "$1" --limit 99999 --json nameWithOwner,sshUrl --jq '.[]|[.nameWithOwner,.sshUrl]|@tsv')
revolver stop
tput cnorm

parallel --no-notice --bar --eta --colsep '\t' "[ ! -d '$2/{1}' ] && git clone --quiet '{2}' '$2/{1}'" :::: <(echo "$repolist")
code=$?

echo "Finished cloning"

exit $code
