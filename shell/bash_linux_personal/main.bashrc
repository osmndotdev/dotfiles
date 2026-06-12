#
###		+--------------------------+
#####	|  MY SHELL PROFILE BEGIN  |
###		+--------------------------+
#


if [ -f "$DOTFILES_DIR/_private/shell/pre.bashrc" ]; then
	source "$DOTFILES_DIR/_private/shell/pre.bashrc"
fi


##### VARIABLES BEGIN #####

### Environment Variables

export EDITOR=micro

export MY_PYTHON_HOME="$HOME/aa/code/python"
export PYTHONPATH="$MY_PYTHON_HOME"
export PYTHONSTARTUP="$DOTFILES_DIR/python/pythonstartup.py"

### PATH Additions

export PATH="$HOME/aa/portablePrograms/bin:$PATH"

### Shell Variables

LIP_INTERFACE=wlp4s0

##### VARIABLES END #####


##### OPTIONS BEGIN #####

# Resources:
# - https://github.com/mrzool/bash-sensible

### General Options

# Prevent file overwrite on stdout redirection (Use `>|` to force redirection to an existing file)
set -o noclobber

# Update window size after every command
# (Linux Mint default) Check the window size after each command and, if necessary, update the values of LINES and COLUMNS
shopt -s checkwinsize

# Automatically trim long paths in the prompt (requires Bash 4.x or newer)
# Also see: https://jichu4n.com/posts/shortening-paths-in-the-bash-prompt-with-prompt_dirtrim/
PROMPT_DIRTRIM=5

### Tab-Completion

# Perform file completion in a case insensitive fashion
bind "set completion-ignore-case on"

# Treat hyphens and underscores as equivalent
bind "set completion-map-case on"

# Immediately add a trailing slash when autocompleting symlinks to directories
bind "set mark-symlinked-directories on"

### History

# (Linux Mint default) Append to the history file, don't overwrite it
shopt -s histappend

# Save multi-line commands as one command
shopt -s cmdhist

# Record each line as it gets issued
# PROMPT_COMMAND='history -a'
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND ;} history -a" # See: https://github.com/wting/autojump?tab=readme-ov-file#known-issues

# Huge history. Doesn't appear to slow things down, so why not?
HISTSIZE=500000
HISTFILESIZE=100000

# Avoid duplicate entries
# (Linux Mint default) Don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth

# Don't record some commands
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

# Use standard ISO 8601 timestamp
# %F equivalent to %Y-%m-%d
# %T equivalent to %H:%M:%S (24-hours format)
HISTTIMEFORMAT='%F %T '

# Enable incremental history search with up/down arrows (also Readline goodness)
# Also see: http://codeinthehole.com/writing/the-most-important-command-line-tip-incremental-history-searching-with-inputrc/
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\e[C": forward-char'
bind '"\e[D": backward-char'

### Directory Navigation

# Prepend cd to directory names automatically
shopt -s autocd 2> /dev/null

# Correct spelling errors during tab-completion
shopt -s dirspell 2> /dev/null

# Correct spelling errors in arguments supplied to cd
shopt -s cdspell 2> /dev/null

### Misc.

# (Linux Mint default) Make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

##### OPTIONS END #####


##### ALIASES BEGIN #####

alias q='exit'

alias cls='clear'

alias p='ping google.com -c 100'

alias l='ls -AC --group-directories-first'
alias ll='ls -Alh --group-directories-first'

mkcd() { mkdir $1 && cd $1; }

alias csum='sha256sum'
csum-txt() { csum $1 > $1.sha256sum.txt; }

alias mux='tmuxinator'

alias httpie='http -v --follow'

alias b='batcat'
alias bp='batcat --paging=always'

alias m='micro'

run-bg() { nohup "$@" > /dev/null 2>&1 & }

alias fx.='run-bg open .'
alias ff='firefox -P'
sudo-xed() { xed "admin://$1"; }

alias c.='code .'
alias cq='code . && exit'
alias cu.='run-bg cursor .'

#lvsrv() { live-server --no-browser --port="$1"; }  # Host is 0.0.0.0 by default

# Print local IP
alias lip='ifconfig $LIP_INTERFACE | grep --color=never -Po "inet \K\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?=  netmask)"'
#alias lip='ip -4 -o address show dev $LIP_INTERFACE | grep --color=never -Po "inet \K\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?=/\d{1,2})"'

alias hib='sudo systemctl hibernate'

#alias wifidriver-on='sudo modprobe iwlwifi'
#alias wifidriver-off='sudo modprobe -r iwlwifi'

# Git-related aliases
alias gcl="git clone"
alias gl="git log"
alias gs="git status"
alias gi="git init"
alias ga="git add"
alias ga.="git add ."
alias gc="git commit"
alias gcm="git commit -m"
alias gf="git fetch"
alias gfa="git fetch --all"
alias gps="git push"
alias gpl="git pull"
alias gup="git fetch --all && git pull"
alias gco="git checkout"
alias gb="git branch"
alias gr="git remote"
alias gra="git remote add"
alias gd="git diff"
alias gdc="git diff --cached"
alias gst="git stash"

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

alias apache-status='service apache2 status'
alias apache-start='sudo service apache2 start'
alias apache-stop='sudo service apache2 stop'
alias apache-restart='sudo service apache2 restart'
alias apache-reload='sudo service apache2 reload'

alias mysql-status='service mysql status'
alias mysql-start='sudo service mysql start'
alias mysql-stop='sudo service mysql stop'
alias mysql-restart='sudo service mysql restart'

alias mongo-status='service mongod status'
alias mongo-start='sudo service mongod start'
alias mongo-stop='sudo service mongod stop'
alias mongo-restart='sudo service mongod restart'

#alias docker-start='sudo systemctl start docker docker.socket containerd'
#alias docker-stop='sudo systemctl stop docker docker.socket containerd'
#alias docker-status='systemctl --user status docker'
#alias docker-start='systemctl --user start docker'
#alias docker-stop='systemctl --user stop docker'

##### ALIASES END #####


##### PROMPT BEGIN #####

#  BLUE_BOLD="\[\033[01;94m\]"
# GREEN_BOLD="\[\033[01;92m\]"
#      CLEAR="\[\033[00m\]"
# PS1="\n${BLUE_BOLD}\u@\h${CLEAR} : ${BLUE_BOLD}\w${CLEAR}\n${GREEN_BOLD}\$${CLEAR} "
PS1='\n\u@\h : \w\n\$ '

##### PROMPT END #####


##### WELCOME BEGIN #####

# Based on art by Hayley Jane Wakenshaw
echo ""
echo "                           /)"
echo "                  /\___/\ (("
echo "                  \'0_0'/  ))"
echo "                  { :Y: }_//"
echo "----------------{_}'-^-'{_}-----------------------------------------------------"
echo ""

##### WELCOME END #####


if [ -f "$DOTFILES_DIR/_private/shell/post.bashrc" ]; then
	source "$DOTFILES_DIR/_private/shell/post.bashrc"
fi


#
###		+------------------------+
#####	|  MY SHELL PROFILE END  |
###		+------------------------+
#
