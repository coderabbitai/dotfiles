#!/usr/bin/env zsh

brew tap molovo/revolver
brew install --quiet revolver

tput civis
revolver --style 'dots2' start 'Syncing local brews...'

# source ~/.brew_local
if [ -f ~/.brew_local ]; then
	source ~/.brew_local
fi

brew tap ejoffe/homebrew-tap
brew tap claui/whence
brew tap bufbuild/buf
brew tap tilt-dev/tap
brew tap noahgorstein/tap
brew tap fluxninja/aperture

revolver stop

# Update homebrew recipes
brew update && brew upgrade && brew cleanup && brew doctor

revolver --style 'dots2' start 'Installing parallel tool...'
brew install --quiet parallel

# check whether ~/.local/share/zinit/zinit.git exists, if not then invoke installation script
if [ ! -d ~/.local/share/zinit/zinit.git ]; then
  revolver update 'Installing zinit...'
  bash -c "NO_INPUT=1 NO_EDIT=1; $(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
fi

PACKAGES+=(
  chezmoi
  zsh
	eza
	dust
	ncdu
	duf
	fd
	git
	spr
	go
	gopls
	gotests
  gops
  delve
  typescript
	universal-ctags
	thefuck
  tmux
  tmux-mem-cpu-load
  node
	python
  autopep8
	rust
	tilt
  ctlptl
	bottom
	helm
	helmfile
  go-jsonnet
	jsonnet-bundler
	tanka
	sops
	terraform
  terragrunt
  tflint
	kubernetes-cli
	jq
	yq
	gh
	kind
	neovim
	asdf
	bat
  bat-extras
	git-delta
	ctop
	kubectx
	fzf
	subversion
	tealdeer
  navi
  watch
	zoxide
	figlet
	ripgrep
	curlie
	vcsh
	vint
	shellcheck
	markdownlint-cli
	markdownlint-cli2
	yamllint
	languagetool
	pylint
	eslint
	cppcheck
	jsonlint
	shfmt
	rustfmt
	golangci-lint
	watchman
	cowsay
	fortune
	vivid
	hyperfine
	sd
	dog
	procs
	broot
	chafa
  exiftool
  pdftohtml
	lesspipe
  mosh
  bats-core
  fpp
  pstree
  smug
  onefetch
  neofetch
  speedtest-cli
	gping
  tty-clock
  lazydocker
  k9s
  kustomize
  kubebuilder
  buf
  grpcurl
  mockery
  urlview
  tree-sitter
  cmake
  hasura-cli
  circleci
  graphviz
  jqp
  openjdk
  openjdk@17
  gradle
  socat
  gum
  aperturectl
  vale
  poetry
  pnpm
  yarn
  pipx
)

if [[ $OSTYPE == 'darwin'* ]]; then
	PACKAGES+=(
    coreutils
		findutils
    gnu-sed
    grep
    gawk
		bash
		wget
		duti
		terminal-notifier
    reattach-to-user-namespace
	)
else
	# override default editor to nvim
	xdg-mime default nvim.desktop text/plain
	PACKAGES+=(
		xclip
		xdotool
		wmctrl
		libnotify
    gcc
	)
  revolver update 'Installing fonts...'
  # declare a map of font urls to font file names (e.g. "FiraCode" to "Fira Code Regular")
  nerd_font='https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3'
  declare -A fonts=(
    "${nerd_font}/DejaVuSansMono.zip" "DejaVu Sans Mono Nerd Font Complete.ttf"
    "${nerd_font}/DroidSansMono.zip" "Droid Sans Mono Nerd Font Complete.otf"
    "${nerd_font}/Go-Mono.zip" "Go Mono Nerd Font Complete.ttf"
    "${nerd_font}/Hack.zip" "Hack Regular Nerd Font Complete Mono.ttf"
    "${nerd_font}/FiraCode.zip" "Fira Code Regular Nerd Font Complete Mono.ttf"
    "${nerd_font}/JetBrainsMono.zip" "JetBrains Mono Regular Nerd Font Complete Mono.ttf"
    "${nerd_font}/Meslo.zip" "Meslo LG S Regular Nerd Font Complete Mono.ttf"
    "${nerd_font}/SourceCodePro.zip" "Sauce Code Pro Nerd Font Complete Mono.ttf"
    "https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji.ttf" "NotoColorEmoji.ttf"
  )
  fonts_dir="${HOME}/.local/share/fonts"
  if [[ ! -d "$fonts_dir" ]]; then
    mkdir -p "$fonts_dir"
  fi
  install_fonts=()
  # search for font patterns (values in $fonts map) in $fonts_dir and add font urls (keys in $fonts map) to $install_fonts list
  for font_url in "${(@k)fonts}"; do
    if [[ -z "$(find "$fonts_dir" -name "${fonts[$font_url]}" -print -quit)" ]]; then
      install_fonts+=("$font_url")
    fi
  done

  # print the list of fonts to install if $installs_fonts is not an empty array
  if [[ ${#install_fonts[@]} -gt 0 ]]; then
    echo "The following fonts will be installed:"
    for font_url in "${install_fonts[@]}"; do
      echo "  ${fonts[$font_url]}"
    done
    for font_url in "${install_fonts[@]}"; do
      echo "Downloading $font_url"
      # $font_file is the base name of $font_url
      font_file=$(basename "${font_url}")
      wget "$font_url"
      # check whether $font_file has a zip extension
      if [[ "$font_file" == *".zip" ]]; then
        unzip -o "$font_file" -d "$fonts_dir"
        rm "$font_file"
      else
        # if not, assume it's a ttf file
        mv "$font_file" "$fonts_dir"
      fi
    done
    find "$fonts_dir" -name '*Windows Compatible*' -delete
    fc-cache -fv
  fi
fi

revolver stop

# get list of currently installed packages and remove them from the list of packages to install
installed_packages=($(brew list))
for installed_package in $installed_packages; do
  PACKAGES=("${(@)PACKAGES:#$installed_package}")
done

revolver --style 'dots2' start 'Installing brew packages...'

# get number of elements in the array $PACKAGES
num_packages=${#PACKAGES[@]}

# check if there are any packages to install
if [[ num_packages -gt 0 ]]; then
  echo "Fetching packages..."
  parallel --no-notice --bar --eta "brew fetch --quiet --formula {1} > /dev/null" ::: ${PACKAGES[@]}

  i=0
  # Loop through Packages and install them
  for package in ${PACKAGES[@]}; do
    ((i++))
    revolver update "Installing package $package ($i of $num_packages)..."
    brew install --quiet --formula $package
  done
fi

if [[ $OSTYPE == 'darwin'* ]]; then

  # check whether /Library/Java/JavaVirtualMachines/openjdk.jdk exists
  if [[ ! -d "/Library/Java/JavaVirtualMachines/openjdk.jdk" ]]; then
    sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
  fi

  revolver update 'Installing iterm2 shell integration...'
  curl -L https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash
	CASKS+=(
		font-dejavu
		font-dejavu-sans-mono-nerd-font
		font-fira-code-nerd-font
		font-droid-sans-mono-nerd-font
		font-go-mono-nerd-font
		font-hack-nerd-font
		font-jetbrains-mono-nerd-font
		font-meslo-lg-nerd-font
		font-victor-mono-nerd-font
		font-monoid-nerd-font
		font-sauce-code-pro-nerd-font
    font-figtree
		iterm2
		adobe-acrobat-reader
		docker
		figma
		github
		google-cloud-sdk
		google-drive
    google-chrome
		notion
		slack
		stats
		zoom
		rectangle-pro
		swiftdefaultappsprefpane # for setting several macOS properties such as default app for opening plaintext files
    # copyq removed as it likely has memory leak on Apple Silicon
	)
  revolver stop

  # check the list of installed casks and remove them from the list of casks to install
  installed_casks=($(brew list --cask))
  for installed_cask in $installed_casks; do
    CASKS=("${(@)CASKS:#$installed_cask}")
  done

  revolver --style 'dots2' start 'Installing cask packages...'

  # check if there are any casks to install
  if [[ ${#CASKS[@]} -gt 0 ]]; then
    echo "Fetching casks..."
    parallel --no-notice --bar --eta "brew fetch --quiet --cask {1} > /dev/null" ::: ${CASKS[@]}
    
    num_casks=${#CASKS[@]}
    i=0
    # Loop through Casks and install them
    for cask in ${CASKS[@]}; do
      ((i++))
      revolver update "Installing cask $cask ($i of $num_casks)..."
      brew install --quiet --cask $cask
    done
  fi

  revolver update 'Updating defaults...'
  # set default terminal to iterm2
  duti -s com.googlecode.iterm2 com.apple.terminal.shell-script shell
  duti -s com.googlecode.iterm2 term
fi

revolver update 'Setting up fzf...'
# setup fzf
yes | $(brew --prefix)/opt/fzf/install

revolver update 'Updating tldr...'
# update tldr
tldr --update

revolver update 'Updating navi cheats...'
old_pwd=$(pwd)
# check whether $(navi info cheats-path)/denisidoro__cheats directory exists
if [ ! -d "$(navi info cheats-path)/denisidoro__cheats" ]; then
  git clone "https://github.com/denisidoro/cheats" "$(navi info cheats-path)/denisidoro__cheats"
else
  cd "$(navi info cheats-path)/denisidoro__cheats" && git pull -q origin master
fi

# if [ ! -d "$(navi info cheats-path)/denisidoro__navi-tldr-pages" ]; then
#   git clone "https://github.com/denisidoro/navi-tldr-pages" "$(navi info cheats-path)/denisidoro__navi-tldr-pages"
# else
#   cd "$(navi info cheats-path)/denisidoro__navi-tldr-pages" && git pull -q origin master
# fi
cd $old_pwd


revolver update 'Installing go packages...'
# go stuff
go install github.com/josharian/impl@latest
go install honnef.co/go/tools/cmd/keyify@latest
go install github.com/koron/iferr@latest
go install github.com/davidrjenni/reftools/cmd/fillstruct@master
go install github.com/orlangure/gocovsh@latest
go install github.com/bufbuild/buf-language-server/cmd/bufls@latest
go install github.com/grafana/jsonnet-language-server@latest

# on linux use system's gcc as cgo compiler as gcc@5 has some linking issues
if [[ $OSTYPE == 'linux'* ]]; then
  go env -w CC=gcc CXX="g++"
fi

revolver update 'Installing npm packages...'
# npm stuff
npm i -q -g turbo
npm i -q -g bash-language-server
npm i -q -g dockerfile-language-server-nodejs

revolver update 'Installing python packages...'
#python stuff
pip3 install --quiet --upgrade pip
pip3 install --quiet --upgrade setuptools
# fluxninja
pip3 install --quiet --upgrade pre-commit
# required for nvim mundo
pip3 install --quiet pynvim
pip3 install --quiet libtmux
pip3 install --quiet tiktoken

revolver update 'Installing gh extensions...'
# gh extensions
gh extension install dlvhdr/gh-dash
gh extension install github/gh-copilot

revolver stop
tput cnorm

# use openjdk@17
brew link --overwrite openjdk@17

echo -e " == Brews Sync'ed == "
