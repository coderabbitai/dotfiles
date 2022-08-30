command_not_found_handler() {
	local CMD="$@"
	if $INSULTS_ENABLED; then
		insult
		echo ""
	fi
	# run thefuck
	TF_SHELL_ALIASES=$(alias)
	TF_CMD=$(
		export TF_SHELL_ALIASES
		export TF_SHELL=zsh
		export TF_ALIAS=fuck
		export TF_HISTORY="$CMD"
		export PYTHONIOENCODING=utf-8
		thefuck THEFUCK_ARGUMENT_PLACEHOLDER
	) && eval $TF_CMD
	test -n "$TF_CMD" && print -s $TF_CMD
	# Return the exit code normally returned on invalid command
	return 127
}
