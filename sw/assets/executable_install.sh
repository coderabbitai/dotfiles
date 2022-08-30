#!/bin/bash

# installer for dotfiles
function brew_shellenv() {
	if [ -d "$HOME/homebrew" ]; then
		eval "$($HOME/homebrew/bin/brew shellenv)"
	else
		if [[ $OSTYPE == 'darwin'* ]]; then
			test -d /opt/homebrew && eval "$(/opt/homebrew/bin/brew shellenv)"
			test -f /usr/local/bin/brew && eval "$(/usr/local/bin/brew shellenv)"
		else
			test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		fi
	fi
}

cd $HOME || exit

# ask the user whether they want to use system's homebrew or use a local install
echo "Do you want to use the system's homebrew (y/n)? Note: Do not choose system's homebrew if you are sharing this machine with other users."
read system_homebrew

# if the user wants to use the system's homebrew, then we'll install it
if [ "$system_homebrew" == "y" ]; then
	# delete local homebrew if it exists
	rm -rf ~/homebrew
	echo "Installing system homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	echo "Installing local homebrew..."
	mkdir homebrew
	curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
fi

brew_shellenv

# install github cli
brew install gh
# install chezmoi
brew install chezmoi
# install zsh
brew install zsh
# add $(which zsh) to the list of shells if it doesn't exist
if ! grep -q $(which zsh) /etc/shells; then
	echo "Adding $(which zsh) to /etc/shells"
	sudo sh -c "echo $(which zsh) >> /etc/shells"
fi
chsh -s $(which zsh)

echo "Authenticating with Github. Please make sure to choose ssh option for authentication."

# authenticate with github
gh auth login -p ssh

# check if $HOME/.git exists and back it up if it does
if [ -d $HOME/.git ]; then
	echo "Backing up $HOME/.git to $HOME/.git.bak"
	mv $HOME/.git $HOME/.git.bak
fi

echo "Setting up .gitconfig_local"
# ask the user to input email address
echo "Please enter your FluxNinja email address:"
read email

# ask the user to input their name
echo "Please enter your name:"
read name

# create .gitconfig_local
# File contents:
# [user]
#   name = $name
#   email = $email
echo "[user]" >$HOME/.gitconfig_local
echo "  name = $name" >>$HOME/.gitconfig_local
echo "  email = $email" >>$HOME/.gitconfig_local

chezmoi init git@github.com:FluxNinja/dotfiles.git
chezmoi apply -v

# run autoupdate script
echo "Running autoupdate script..."
~/sw/bin/autoupdate.zsh --force
# if autoupdate failed, exit
if [ $? -ne 0 ]; then
	echo "Failed to run autoupdate script"
	exit 1
fi

# reboot computer
echo "Restarting computer..."
sudo reboot
