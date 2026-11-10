# This is a zsh file; shellcheck only understands bash and reports false positives.
# shellcheck disable=all

# Requires:
#   - git, inside a repo whose remote is named `origin`
# Config:
#   - Source after `compinit`; the `compdef` line at the bottom runs at source time

# Prune stale remote refs, then if the given branch's upstream is gone, rename it with a "merged/" prefix.
gb-retire() {
  local branch="$1"
  if [[ -z "$branch" ]]; then
    echo "Usage: gb-retire <branch>"
    return 1
  fi
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "Branch '$branch' does not exist."
    return 1
  fi
  git remote prune origin
  if [[ "$(git for-each-ref --format='%(upstream:track)' "refs/heads/$branch")" == "[gone]" ]]; then
    git branch -m "$branch" "merged/$branch"
    echo "Retired '$branch' → 'merged/$branch'."
  else
    echo "Branch '$branch' still exists in origin; not retiring."
  fi
}

# Complete local branch names (excluding already-retired ones)
_gb-retire() {
  local -a branches
  branches=(${(f)"$(git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)"})
  branches=(${branches:#merged/*})
  _describe 'local branch' branches
}
compdef _gb-retire gb-retire
