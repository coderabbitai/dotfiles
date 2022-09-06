#!/usr/bin/env bash

# if ~/Work/fluxninja/RM exists rename it to ~/Work/fluxninja/cloud
if [ -d ~/Work/FluxNinja/RM ]; then
	mv ~/Work/FluxNinja/RM ~/Work/FluxNinja/cloud
fi

if [ -d ~/Work/FluxNinja ]; then
	mv ~/Work/FluxNinja ~/Work/fluxninja
	# in each repo under ~/Work/fluxninja/* replace "git@github.com:FluxNinja" with "git@github.com:fluxninja" in .git/config
	for repo in ~/Work/fluxninja/*; do
		SED="sed"
		# check whether gsed exists
		if [ -x "$(command -v gsed)" ]; then
			SED="gsed"
		fi
		$SED -i 's/git@github.com:FluxNinja/git@github.com:fluxninja/g' "$repo"/.git/config
	done
fi

gh_clone_all.sh fluxninja ~/Work
pull_all.sh ~/Work/fluxninja

# check whether ~/Work/fluxninja/cloud/services/oss/aperture is not a symlink
if ! [ -L ~/Work/fluxninja/cloud/services/oss/aperture ]; then
	# check whether ~/Work/fluxninja/cloud is on master or main git branch
	branch="$(git -C ~/Work/fluxninja/cloud rev-parse --abbrev-ref HEAD)"
	if [ "$branch" == "master" ] || [ "$branch" == "main" ]; then
		rm -rf ~/Work/fluxninja/cloud/services/oss/aperture
	fi
else
	unlink ~/Work/fluxninja/cloud/services/oss/aperture
fi

# symlink aperture in cloud
if [ ! -d ~/Work/fluxninja/cloud/services/oss/aperture ]; then
	ln -s ~/Work/fluxninja/aperture ~/Work/fluxninja/cloud/services/oss/aperture
fi

if [ ! -d ~/Work/fluxninja/aperture-tech-docs/local ]; then
	ln -s ~/Work/fluxninja/aperture/docs/content ~/Work/fluxninja/aperture-tech-docs/local
fi

PRECOMMIT_DIRS=(
	~/Work/fluxninja/cloud
	~/Work/fluxninja/aperture
	~/Work/fluxninja/aperture-tech-docs
	~/Work/fluxninja/aperture-go
)

for dir in "${PRECOMMIT_DIRS[@]}"; do
	if [ -d "$dir" ]; then
		echo "Installing precommit hooks in $dir"
		pushd "$dir" >/dev/null || continue
		pre-commit install --hook-type={pre-commit,commit-msg,prepare-commit-msg}
		pre-commit install-hooks
		popd >/dev/null || continue
	fi
done

pushd ~/Work/fluxninja/aperture >/dev/null || exit 1
make install-go-tools
make install-python-tools
popd >/dev/null || exit 1
