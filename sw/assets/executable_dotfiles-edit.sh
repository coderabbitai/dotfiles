#!/bin/sh

# shell script to open dotfiles editor in nvim

# the script takes an argument which can be either empty or "personal"
# if the argument is empty, it will open the global dotfiles
# if the argument is "personal", it will open the personal dotfiles
cd $HOME

if [ "$1" = "personal" ]; then
	nvim -p .gitconfig_local .vimrc_local .vimrc_plugins .autoupdate_local.zsh .tmux.conf_local .brew_local
else
	nvim -p .vimrc .config/nvim/init.vim .config/nvim/coc-settings.json .zshrc .gitconfig .gitignore .zprofile .tmux.conf .tmux.conf.settings ~/sw/bin/autoupdate.zsh ~/sw/bin/sync_brews.sh
fi
