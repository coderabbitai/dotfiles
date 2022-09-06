#!/usr/bin/env zsh

brew tap molovo/revolver
brew install --quiet revolver

tput civis
revolver --style 'dots2' start 'Syncing brews...'

# source ~/.brew_local
if [ -f ~/.brew_local ]; then
	source ~/.brew_local
fi

# uninstall gcc@5 if it exists
if brew ls --versions gcc@5 > /dev/null; then
  # uninstall gcc@5
  brew uninstall gcc@5
fi

# uninstall pre-commit if it exists
if brew ls --versions pre-commit > /dev/null; then
  # uninstall pre-commit
  brew uninstall pre-commit
fi


# tap withgraphite
brew tap withgraphite/tap
# add spr repo
brew tap ejoffe/homebrew-tap
# install whence
brew tap claui/whence
# buf
brew tap bufbuild/buf
# tilt-dev
brew tap tilt-dev/tap

if [[ $OSTYPE == 'darwin'* ]]; then
	brew tap homebrew/cask-fonts
fi

revolver update 'Updating existing brews...'

# Update homebrew recipes
brew update && brew upgrade && brew cleanup && brew doctor

revolver update 'Installing parallel tool...'
brew install --quiet parallel

# check whether ~/.local/share/zinit/zinit.git exists, if not then invoke installation script
if [ ! -d ~/.local/share/zinit/zinit.git ]; then
  revolver update 'Installing zinit...'
  bash -c "NO_INPUT=1 NO_EDIT=1; $(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
fi

PACKAGES+=(
  chezmoi
  zsh
	exa
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
	universal-ctags
	thefuck
  tmux
  tmux-mem-cpu-load
	node@16
  node
	python
	etcd
	prometheus
	rust
	tilt
  tilt-dev/tap/ctlptl
	bottom
	helm
	helmfile
  jsonnet
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
  withgraphite/tap/graphite
	kind
	neovim
	asdf
	bat
  bat-extras
	git-delta
	ctop
	kubectx
	fzf
	svn
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
	write-good
	markdownlint-cli
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
  darksky-weather
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
  bufbuild/buf/buf
  grpcurl
  mockery
  urlview
  tree-sitter
  cmake
  hasura-cli
  yarn
  circleci
  graphviz
)

if [[ $OSTYPE == 'darwin'* ]]; then
	PACKAGES+=(
    coreutils
		findutils
    gnu-sed
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
    neovim-qt
	)
  revolver update 'Installing fonts...'
  # declare a map of font urls to font file names (e.g. "FiraCode" to "Fira Code Regular")
  nerd_font='https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0'
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

echo "Fetching packages..."
parallel --no-notice --bar --eta "brew fetch --quiet --formula {1} > /dev/null" ::: ${PACKAGES[@]}

revolver --style 'dots2' start 'Installing...'

# get number of elements in the array $PACKAGES
num_packages=${#PACKAGES[@]}
i=0
# Loop through Packages and install them
for package in ${PACKAGES[@]}; do
  ((i++))
  revolver update "Installing package $package ($i of $num_packages)..."
	brew install --quiet --formula $package
done

if [[ $OSTYPE == 'darwin'* ]]; then
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
		vimr
		iterm2
		adobe-acrobat-reader
		docker
		figma
		github
		google-cloud-sdk
		google-drive
		notion
		slack
		stats
		zoom
		rectangle-pro
		swiftdefaultappsprefpane # for setting several macOS properties such as default app for opening plaintext files
    # copyq removed as it likely has memory leak on Apple Silicon
	)
  revolver stop

  echo "Fetching casks..."
	parallel --no-notice --bar --eta "brew fetch --quiet --cask {1} > /dev/null" ::: ${CASKS[@]}
  
  revolver --style 'dots2' start 'Installing...'

  num_casks=${#CASKS[@]}
  i=0
	# Loop through Casks and install them
	for cask in ${CASKS[@]}; do
    ((i++))
    revolver update "Installing cask $cask ($i of $num_casks)..."
		brew install --quiet --cask $cask
	done
  revolver update 'Updating defaults...'
	# on macos override default editor to vimr
  duti -s com.qvacua.vimr public.json all
  duti -s com.qvacua.vimr public.plain-text all
  duti -s com.qvacua.vimr public.python-script all
  duti -s com.qvacua.vimr public.shell-script all
  duti -s com.qvacua.vimr public.source-code all
  duti -s com.qvacua.vimr public.text all
  duti -s com.qvacua.vimr public.unix-executable all
  duti -s com.qvacua.vimr .go all
  duti -s com.qvacua.vimr .mod all
  duti -s com.qvacua.vimr .work all
  duti -s com.qvacua.vimr .c all
  duti -s com.qvacua.vimr .cc all
  duti -s com.qvacua.vimr .cpp all
  duti -s com.qvacua.vimr .cs all
  duti -s com.qvacua.vimr .css all
  duti -s com.qvacua.vimr .java all
  duti -s com.qvacua.vimr .js all
  duti -s com.qvacua.vimr .sass all
  duti -s com.qvacua.vimr .scss all
  duti -s com.qvacua.vimr .less all
  duti -s com.qvacua.vimr .vue all
  duti -s com.qvacua.vimr .cfg all
  duti -s com.qvacua.vimr .json all
  duti -s com.qvacua.vimr .jsx all
  duti -s com.qvacua.vimr .log all
  duti -s com.qvacua.vimr .lua all
  duti -s com.qvacua.vimr .md all
  duti -s com.qvacua.vimr .php all
  duti -s com.qvacua.vimr .pl all
  duti -s com.qvacua.vimr .py all
  duti -s com.qvacua.vimr .rb all
  duti -s com.qvacua.vimr .ts all
  duti -s com.qvacua.vimr .tsx all
  duti -s com.qvacua.vimr .txt all
  duti -s com.qvacua.vimr .cfg all
  duti -s com.qvacua.vimr .conf all
  duti -s com.qvacua.vimr .yaml all
  duti -s com.qvacua.vimr .yml all
  duti -s com.qvacua.vimr .toml all
  duti -s com.qvacua.vimr .xml all
  duti -s com.qvacua.vimr .xsl all
  duti -s com.qvacua.vimr .xsd all
  duti -s com.qvacua.vimr .vim all
  duti -s com.qvacua.vimr .vimrc all
  duti -s com.qvacua.vimr .gitconfig all
  duti -s com.qvacua.vimr .gitignore all
  duti -s com.qvacua.vimr .config all
  duti -s com.qvacua.vimr .sh all
  duti -s com.qvacua.vimr .zsh all
  duti -s com.qvacua.vimr .bash all

  # set default terminal to iterm2
  duti -s com.googlecode.iterm2 com.apple.terminal.shell-script shell
  duti -s com.googlecode.iterm2 term
fi

revolver update 'Installing...'

# setup fzf
yes | $(brew --prefix)/opt/fzf/install

# update tldr
tldr --update

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

# on linux use system's gcc as cgo compiler as gcc@5 has some linking issues
if [[ $OSTYPE == 'linux'* ]]; then
  go env -w CC=gcc CXX="g++"
fi

revolver update 'Installing npm packages...'
# npm stuff
npm i -q -g bash-language-server

revolver update 'Installing python packages...'
#python stuff
pip3 install --quiet --upgrade pip
pip3 install --quiet --upgrade setuptools
# fluxninja
pip3 install --quiet --upgrade pre-commit
# required for nvim mundo
pip3 install --quiet pynvim
pip3 install --quiet libtmux

# gh extensions
gh extension install dlvhdr/gh-dash

revolver stop
tput cnorm

echo -e " == Brews Sync'ed == "
