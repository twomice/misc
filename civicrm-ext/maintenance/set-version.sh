#!/bin/bash
set -euo pipefail

# --- config / args ---
NEW_VERSION="${1}"
EXT_DIR="${2:-$(pwd)}"

# --- sanity checks ---
if [ ! -d "$EXT_DIR" ]; then
  echo "Error: directory not found: $EXT_DIR"
  exit 1
fi

cd "$EXT_DIR"

if [ ! -f "info.xml" ]; then
  echo "Error: info.xml not found in $EXT_DIR"
  exit 1
fi

if [ ! -d ".git" ]; then
  echo "Error: not a git repo (no .git directory)"
  exit 1
fi

# ensure on master
branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" != "master" ]; then
  echo "Error: not on master branch (current: $branch)"
  exit 1
fi

# ensure clean working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: uncommitted changes present"
  exit 1
fi

# pull latest from origin/master
git pull origin master

# --- extract version ---
current_version=$(grep -oP '(?<=<version>)[^<]+' info.xml || true)

echo "Current version: $current_version"
echo "New version:     $NEW_VERSION"

# --- update info.xml ---
sed -i "s#<version>[^<]*</version>#<version>${NEW_VERSION}</version>#" info.xml

# --- commit ---
git add info.xml
git commit -m "Increment version to ${NEW_VERSION}"

# --- tag ---
tag="v${NEW_VERSION}"
git tag "$tag"

# -- confirm, then push --
echo
git remote -v
echo "NOTE REMOTES ABOVE! Incremented version to ${NEW_VERSION} and tagged as ${tag}. About to push commit and tag to origin/master. [Enter to continue, Ctrl+C to quit now]"
read continue
git push origin master
git push origin "$tag"

echo "Done: ${tag}"