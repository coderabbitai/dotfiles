#!/usr/bin/env zsh

# Inspired by https://github.com/m-ou-se/config/blob/master/shellrc.

# Set a color in the terminal palette.
# \param 1 The index in the pallete.
# \param 2 is a hexadecimal RGB color code.
function set_color {
	if [ "$TERM" = "linux" ]; then
		[ $1 -lt 16 ] && printf $'\e]P%X%s' "$1" "$2"
	else
		printf $'\e]4;%s;#%s\e\\' "$1" "$2"
	fi
}

local black=353535
local white=efe1bf

# Set default foreground / background colors for terminals that support it.
printf "\e]10;#$white"
printf "\e]11;#$black"

# Set terminal colors.
set_color  0 $black # black
set_color  1 d73925 # red
set_color  2 a8a521 # green
set_color  3 dfa82a # yellow
set_color  4 549699 # blue
set_color  5 bf7897 # magenta
set_color  6 79aa7d # cyan
set_color  7 b7a996 # white
set_color  8 a39586 # bright black
set_color  9 fe6142 # bright red
set_color 10 c4c431 # bright green
set_color 11 fcc73c # bright yellow
set_color 12 94b3a8 # bright blue
set_color 13 dc9aab # bright magenta
set_color 14 9dc98e # bright cyan
set_color 15 fffefe # bright white
# Set colors for 256
set_color 17 076678 # dark blue
set_color 22 79740e # dark green
set_color 52 9d0006 # dark red
set_color 53 8f3f71 # dark magenta
