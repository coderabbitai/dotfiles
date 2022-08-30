#!/usr/bin/env bash
# If you source this file, it will set WTTR_PARAMS as well as show weather.

# WTTR_PARAMS is space-separated URL parameters, many of which are single characters that can be
# lumped together. For example, "F q m" behaves the same as "Fqm".
if [[ -z "$WTTR_PARAMS" ]]; then
	# Form localized URL parameters for curl
	if [[ -t 1 ]] && [[ "$(tput cols)" -lt 125 ]]; then
		WTTR_PARAMS+='n'
	fi 2>/dev/null
	for _token in $(locale LC_MEASUREMENT); do
		case $_token in
		1) WTTR_PARAMS+='m' ;;
		2) WTTR_PARAMS+='u' ;;
		esac
	done 2>/dev/null
	unset _token
	export WTTR_PARAMS
fi

wttr() {
	local location="${1// /+}"
	command shift
	local args=""
	for p in $WTTR_PARAMS "$@"; do
		args+=" --data-urlencode $p "
	done
	# save the output of curl to a file
	tempfile=$(mktemp)
	curl -fGsS -H "Accept-Language: ${LANG%_*}" $args --compressed "wttr.in/${location}" >"$tempfile"
	# check whether the file is not empty
	if [[ -s "$tempfile" ]]; then
		# remove last line of the file on linux and macos
		if [[ "$OSTYPE" == "linux"* ]]; then
			sed -i '$d' "$tempfile"
		elif [[ "$OSTYPE" == "darwin"* ]]; then
			sed -i '' -e '$ d' "$tempfile"
		fi
	else
		weather --hide-icon >"$tempfile"
	fi
	# show current date and time
	echo -e "Weather on $(date +"%A, %d %B %Y %H:%M")"
	cat "$tempfile"
	# remove the file
	rm "$tempfile"
}

wttr "$@"
