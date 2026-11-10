# This is a zsh file; shellcheck only understands bash and reports false positives.
# shellcheck disable=all

# Requires: nothing external
# Config: none

hoist() {
	local dir base parent
	dir=$PWD
	base=${dir:t}
	parent=${dir:h}

	# Safety guard: refuse to run in or above $HOME
	if [[ "$dir" == "/" || "$dir" == "$HOME" || "$dir" == /home* ]]; then
		print -r -- "Refusing to hoist from protected directory: $dir"
		return 1
	fi
	if [[ "$parent" == "/" || "$parent" == "$HOME" || "$parent" == /home* ]]; then
		print -r -- "Refusing to hoist into protected directory: $parent"
		return 1
	fi

	# Temporarily allow globs that match nothing
	setopt localoptions null_glob

	# Move visible and hidden files (except . and ..)
	mv -- $dir/* $dir/.[!.]* $parent/ 2>/dev/null

	# Step up and remove the old directory
	cd "$parent" || return
	rmdir -- "$dir" 2>/dev/null && print -r -- "Hoisted '$base' into '$parent'"
}
