#
###		+--------------------------+
#####	|  MY SHELL PROFILE BEGIN  |
###		+--------------------------+
#

# This is a zsh file; shellcheck only understands bash and reports false positives.
# shellcheck disable=all


if [ -f "$DOTFILES_DIR/_private/shell/pre.zshrc" ]; then
	source "$DOTFILES_DIR/_private/shell/pre.zshrc"
fi


##### TODO BEGIN #####

# For React Native
export JAVA_HOME=`/usr/libexec/java_home -v 17`
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools

# CodeQuick
source $HOME/aa/code/shell/codequick/contrib/cq.zsh

# Cursor Window Manager
source $HOME/aa/code/_cq/reals/cq-uqZHV0KQ/contrib/cuwm.zsh

##### TODO END #####


##### VARIABLES BEGIN #####

### Environment Variables

export XDG_CONFIG_HOME="/Users/osman/.config"
export XDG_DATA_DIRS="/opt/homebrew/share:$XDG_DATA_DIRS"

export EDITOR=/opt/homebrew/bin/micro

export MY_PYTHON_HOME="$HOME/aa/code/python"
export PYTHONPATH="$MY_PYTHON_HOME"
export PYTHONSTARTUP="$DOTFILES_DIR/python/pythonstartup.py"

### PATH Additions

export PATH="$HOME/aa/programFiles/bin:$HOME/go/bin:/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"

### Shell Variables

LIP_INTERFACE=en0

##### VARIABLES END #####


##### OPTIONS BEGIN #####

setopt AUTO_CD

# Don't store consecutive duplicates in history
setopt HIST_IGNORE_DUPS

# Append history lines as soon as they're entered (instead of only on shell exit)
setopt INC_APPEND_HISTORY

##### OPTIONS END #####


##### COMPLETION BEGIN #####

# Load the completion system (also enables `compdef` for custom completers below)
autoload -Uz compinit && compinit

# Try exact completions first, then fall back to case-insensitive matches.
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

##### COMPLETION END #####


##### ALIASES BEGIN #####

alias dotf='source ~/.zshrc'

alias q='exit'

alias cls='clear'

alias p='ping google.com -c 100'

alias l='ls -AFG'
alias ll='ls -AFGlh'

mkcd() { mkdir $1 && cd $1; }

alias csum='sha256sum'
csum-txt() { csum $1 > $1.sha256sum.txt; }

alias mux='tmuxinator'
alias mux-ls='ls -1 ~/.config/tmuxinator/'
mux-gedit() { cot ~/.config/tmuxinator/$1.yaml; }

alias httpie='http -v --follow'

alias b='bat'
alias bp='bat --paging=always'

alias m='micro'

alias rga='rg -uu' # ripgrep all

# TODO run-bg

alias skhdrc='cot ~/.skhdrc'
alias skhd-logs='tail -n 0 -f /tmp/skhd_osman.err.log'

pgbin() { /opt/homebrew/opt/postgresql@15/bin/$1; }

alias fx.='open .'
alias fxr='open -R'
alias ff='/Applications/Firefox.app/Contents/MacOS/firefox -P > /dev/null'

alias c.='code .'
alias z.='zed .'
alias cu.='cursor .'

# Print local IP
alias lip='ifconfig $LIP_INTERFACE | ggrep --color=never -Po "inet \K\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?= netmask)"'
#alias lip='ip -4 -o address show dev $LIP_INTERFACE | grep --color=never -Po "inet \K\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?=/\d{1,2})"'

# Git-related aliases
alias gcl="git clone"
alias gl="git log"
alias gla="git log --graph --all"
alias gs="git status"
alias gi="git init"
alias ga="git add"
alias ga.="git add ."
alias gc="git commit"
alias gcm="git commit -m"
gf() {
  local y='\033[0;33m'
  local w='\033[0m'
  echo "⚠️ ${y}git pull${w} also fetches all branches before attempting to fast-forward from upstream.
So you probably don't need to use ${y}git fetch${w}."
}
gfa() {
  local y='\033[0;33m'
  local w='\033[0m'
  echo "⚠️ ${y}git fetch --all${w} fetches all branches from all remotes.
${y}git fetch${w} fetches all branches from origin.
So you probably want to use ${y}git fetch${w}."
}
alias gps="git push"
alias gpsu="git push -u"
alias gpsuo="git push -u origin"
alias gpsuom="git push -u origin main"
alias gpl="git pull"
gup() {
  local y='\033[0;33m'
  local w='\033[0m'
  echo "⚠️ ${y}git pull${w} also fetches all branches before attempting to fast-forward from upstream.
So just use ${y}git pull${w} (alias: ${y}gpl${w})."
}
gco() {
  local y='\033[0;33m'
  local w='\033[0m'
  echo "⚠️ Stop using git checkout for everything!

Switch to a branch:
${y}gco main${w} → ${y}gsw main${w}

Create a new branch:
${y}gco -b feat1${w} → ${y}gswc feat1${w}

Create a new branch based on a commit:
${y}gco -b feat1 1ee933a5${w} → ${y}gswc feat1 1ee933a5${w}

Switch to a previous commit:
${y}gco 1ee933a5${w} → ${y}gswd 1ee933a5${w}

Switch to the N-th previous commit:
${y}gco HEAD~1${w} → ${y}gswd HEAD~1${w}"
}
alias gb="git branch"
alias gbl="git branch --color=always | grep -v '^\s*merged\/'"
alias gr="git remote"
alias grl="git remote -v"
alias gra="git remote add"
alias grao="git remote add origin"
alias grso="git remote set-url origin"
alias gd="git diff"
alias gdc="git diff --cached"
alias gst="git stash"
alias gsw="git switch"
alias gswc="git switch -c" # --create
alias gswd="git switch -d" # --detach
alias gmff="git merge --ff-only"

# https://superuser.com/a/1559424
alias git-undo-chmod="git diff -p | grep -E '^(diff|old mode|new mode)' | sed -e 's/^old/NEW/;s/^new/old/;s/^NEW/new/' | git apply"
# TODO Test and implement for Bash

# Python-related aliases
alias seba='source env/bin/activate'
alias deac='deactivate'
alias py-init='python -m venv env && seba'
py-new() { mkcd $1 && py-init; }
alias pip-i='pip install -r requirements.txt'
pip-add() { pip install "$@" && printf "%s\n" "$@" >> requirements.txt; }
alias py-srv='python -m http.server --bind localhost'
alias py-srv-public='echo -n "Your local IP address is: "; lip; py-srv'
# py-run() {
# 	local SCRIPT_NAME=$1;
# 	shift;
# 	python "$MY_PYTHON_HOME/_run/$SCRIPT_NAME.py" $@;
# }

# Java-related aliases
alias jdk-list='/usr/libexec/java_home -V'
jdk-use() { export JAVA_HOME=$(/usr/libexec/java_home -v $1); }

# Caddy-related aliases
alias caddy-status='sudo brew services info caddy'
alias caddy-start='sudo brew services start caddy'
alias caddy-stop='sudo brew services stop caddy'
alias caddy-restart='sudo brew services restart caddy'
# Seems like Homebrew's "reload" is just an alias for "restart"
alias caddy-path='echo $HOMEBREW_PREFIX/etc/Caddyfile'
alias caddy-view='b $HOMEBREW_PREFIX/etc/Caddyfile'
alias caddy-edit='micro $HOMEBREW_PREFIX/etc/Caddyfile'
alias caddy-gedit='cot $HOMEBREW_PREFIX/etc/Caddyfile'
alias caddy-validate='caddy validate --config $HOMEBREW_PREFIX/etc/Caddyfile --adapter caddyfile'
alias caddy-fmt='caddy fmt --config $HOMEBREW_PREFIX/etc/Caddyfile --overwrite'
alias caddy-reload='caddy reload --config $HOMEBREW_PREFIX/etc/Caddyfile'

# Solana-related aliases
alias scl='solana config set -ul' # Localnet
alias scd='solana config set -ud' # Devnet
alias stv='cd && solana-test-validator --reset'
alias sl='solana logs'
alias csd='npx create-solana-dapp'
alias ai='anchor init --template multiple'
alias ab='anchor build && anchor keys sync'
alias at='anchor test --skip-local-validator'
alias ad='anchor deploy --provider.cluster localnet'

alias pab='pnpm approve-builds'

alias ni='nice -n 15'

alias alttab-restart='killall AltTab 2>/dev/null; while pgrep -x AltTab >/dev/null; do sleep 0.1; done; open /Applications/AltTab.app'

##### ALIASES END #####


##### FUNCTIONS BEGIN #####

source "$DOTFILES_DIR/shell/functions/zsh/cc.zsh"
source "$DOTFILES_DIR/shell/functions/zsh/gb-retire.zsh"
source "$DOTFILES_DIR/shell/functions/zsh/hoist.zsh"
source "$DOTFILES_DIR/shell/functions/zsh/portkill.zsh"

##### FUNCTIONS END #####


##### PROMPT BEGIN #####

PROMPT=$'
🐸 %{\e[32m%}%n@%m%{\e[0m%} : %{\e[32m%}%~%{\e[0m%}
 %% '

# RPROMPT=$'%{\e[2m%}%*%{\e[0m%}'

##### PROMPT END #####


##### WELCOME BEGIN #####

# Art by Joan Stark
# https://www.asciiart.eu/buildings-and-places/cities
echo ""
echo -e "                           .|                                                   "
echo -e "                           | |                                                  "
echo -e "                           |'|            ._____                                "
echo -e "                   ___    |  |            |.   |' .---\"|                        "
echo -e "           _    .-'   '-. |  |     .--'|  ||   | _|    |                        "
echo -e "        .-'|  _.|  |    ||   '-__  |   |  |    ||      |                        "
echo -e "        |' | |.    |    ||       | |   |  |    ||      |                        "
echo -e "________|  '-'     '    \"\"       '-'   '-.'    '\`      |________________________"
echo -e "\e[34m~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\e[0m"
echo -e "\e[34m~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\e[0m"
echo -e "\e[34m~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\e[0m"
echo -e "\e[34m~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\e[0m"
echo ""

##### WELCOME END #####


if [ -f "$DOTFILES_DIR/_private/shell/post.zshrc" ]; then
	source "$DOTFILES_DIR/_private/shell/post.zshrc"
fi


#
###		+------------------------+
#####	|  MY SHELL PROFILE END  |
###		+------------------------+
#
