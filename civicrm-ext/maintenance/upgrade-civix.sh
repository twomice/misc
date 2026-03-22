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

# --- run civix upgrade ---
echo "Running civix upgrade..."
civix upgrade -n

# --- ensure something changed ---
if git diff --quiet && git diff --cached --quiet; then
  echo "No changes from civix upgrade; nothing to commit."
  exit 0
fi

# --- extract civix format version ---
format_version=$(sed -n 's:.*<format>\(.*\)</format>.*:\1:p' info.xml)

if [ -z "$format_version" ]; then
  echo "Error: could not find <format> in info.xml after civix upgrade"
  exit 1
fi

# --- commit all changes ---
git add -A
git commit -m "civix upgrade, format: ${format_version}"

# --- push ---
git push origin master

echo "Done: civix upgrade, format: ${format_version}"
