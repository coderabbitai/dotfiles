#!/usr/bin/env bash

RESET="\e[0m"
RED_BRIGHT="\e[91m"
YELLOW_BRIGHT="\e[93m"
GREEN_BRIGHT="\e[92m"

CUT="cut"
# check whether gcut command exists
if command -v gcut >/dev/null 2>&1; then
	CUT="gcut"
fi

# check whether it's a git repo and remote is github
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	exit 0
fi

if ! git remote -v | grep -q "github.com"; then
	exit 0
fi

gh_checks="$(gh pr checks 2>/dev/null | $CUT --fields=2)"
gh_status_mark=""
# extract the number of fail checks
gh_fail_checks="$(echo "$gh_checks" | grep -c fail)"
# extract the number of pass checks
gh_pass_checks="$(echo "$gh_checks" | grep -c pass)"
# extract the number of pending checks
gh_pending_checks="$(echo "$gh_checks" | grep -c pending)"
if [[ $gh_pending_checks -gt 0 ]]; then
	gh_status_mark+="$(echo -e "${YELLOW_BRIGHT}⧖ ${gh_pending_checks} ${RESET}")"
fi
if [[ $gh_fail_checks -gt 0 ]]; then
	gh_status_mark+="$(echo -e "${RED_BRIGHT}✘ ${gh_fail_checks} ${RESET}")"
fi
if [[ $gh_pass_checks -gt 0 ]]; then
	gh_status_mark+="$(echo -e "${GREEN_BRIGHT}✔ ${gh_pass_checks} ${RESET}")"
fi
echo -e "$gh_status_mark"
