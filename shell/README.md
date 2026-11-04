# dotfiles/shell

Append the given snippet to the existing shell config, so that the environment-specific defaults will be preserved.

For the profile "bash_linux_personal", add this to the `.bashrc`:

```sh
#
###
#####
export DOTFILES_DIR="$HOME/aa/dotfiles"
DOTFILES_SHELL_PROFILE="bash_linux_personal"
source "$DOTFILES_DIR/shell/profiles/$DOTFILES_SHELL_PROFILE/main.bashrc"
#####
###
#
```

For the profile "zsh_macos_personal", add this to the `.zshrc`:

```sh
#
###
#####
export DOTFILES_DIR="$HOME/aa/dotfiles"
DOTFILES_SHELL_PROFILE="zsh_macos_personal"
source "$DOTFILES_DIR/shell/profiles/$DOTFILES_SHELL_PROFILE/main.zshrc"
#####
###
#
```
