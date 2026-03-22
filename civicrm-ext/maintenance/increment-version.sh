#!/bin/bash
set -euo pipefail

# --- config / args ---
EXT_DIR="${1:-$(pwd)}"

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

if [ -z "$current_version" ]; then
  echo "Error: could not find <version> in info.xml"
  exit 1
fi

# validate semver (x.y.z)
if ! [[ "$current_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: version is not semver (x.y.z): $current_version"
  exit 1
fi

IFS='.' read -r major minor patch <<< "$current_version"
new_patch=$((patch + 1))
new_version="${major}.${minor}.${new_patch}"

echo "Current version: $current_version"
echo "New version:     $new_version"

# --- update info.xml ---
# portable sed (handles GNU + BSD)
if sed --version >/dev/null 2>&1; then
  # GNU sed
  sed -i "s/<version>${current_version}<\/version>/<version>${new_version}<\/version>/" info.xml
else
  # BSD sed (mac)
  sed -i '' "s/<version>${current_version}<\/version>/<version>${new_version}<\/version>/" info.xml
fi

# --- commit ---
git add info.xml
git commit -m "Increment version to ${new_version}"

# --- tag ---
tag="v${new_version}"
git tag "$tag"

# -- push --
#echo
#git remote -v
#echo "NOTE REMOTES ABOVE! Incremented version to ${new_version} and tagged as ${tag}. About to push commit and tag to origin/master. [Enter to continue, Ctrl+C to quit now]"
#read continue
git push origin master
git push origin "$tag"

echo "Done: ${tag}"