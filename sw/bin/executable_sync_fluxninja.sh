#!/usr/bin/env bash

gh_clone_all.sh fluxninja ~/Work
pull_all.sh ~/Work/fluxninja

# symlink aperture in cloud
if [ ! -d ~/Work/fluxninja/cloud/services/aperture ]; then
	ln -s ~/Work/fluxninja/aperture ~/Work/fluxninja/cloud/services/aperture
fi

if [ ! -d ~/Work/fluxninja/aperture-tech-docs/local ]; then
	ln -s ~/Work/fluxninja/aperture/docs/content ~/Work/fluxninja/aperture-tech-docs/local
fi

PRECOMMIT_DIRS=(
	~/Work/fluxninja/cloud
	~/Work/fluxninja/aperture
	~/Work/fluxninja/aperture-tech-docs
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
vale sync
popd >/dev/null || exit 1

pushd ~/Work/fluxninja/aperture-tech-docs >/dev/null || exit 1
yarn install
vale sync
popd >/dev/null || exit 1

pushd ~/Work/fluxninja/fluxninja-website >/dev/null || exit 1
yarn install
popd >/dev/null || exit 1

pushd ~/Work/fluxninja/cloud/ops/apps/opsninja >/dev/null || exit 1
pip3 install .
popd >/dev/null || exit 1
