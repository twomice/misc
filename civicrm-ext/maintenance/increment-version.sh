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
tag="v${new_version}"

echo "Current version: $current_version"
echo "New version:     $new_version"

# --- find last tag ---
last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "$last_tag" ]; then
  range=""
else
  range="${last_tag}..HEAD"
fi

if git diff --quiet "${range}"; then
  echo ""
  echo "ATTENTION: No changes found since last tag ${last_tag}."
  echo "           You probably don't want to continue."
  read -r -p "           Press Enter to continue incrementing version anyway, or Ctrl+C to cancel... "
fi

# --- generate draft notes ---
notes=$(git log $range --no-merges --pretty=format:"- %s" || true)
merge_notes=$(git log $range --merges --pretty=format:"- %b" || true)

draft_notes=$(printf "%s\n%s\n" "$notes" "$merge_notes" \
  | sed '/^$/d' \
  | sed '/^Merge /d' \
  | awk '!seen[$0]++')

# --- temp file ---
tmpfileReleaseNotes=$(mktemp)

{
  echo "## ${tag}"
  echo
  if [ -n "$draft_notes" ]; then
    echo "$draft_notes"
  else
    echo "- (No significant changes)"
  fi
  echo
} > "$tmpfileReleaseNotes"

# --- edit ---
echo "Opening editor for release notes..."
${EDITOR:-vi} "$tmpfileReleaseNotes"

# --- create stub changelog if none ---
if [ ! -f "CHANGELOG.md" ]; then
  echo "## Earlier versions" >> CHANGELOG.md
  echo "[No changelog for earlier versions]" >> CHANGELOG.md
fi

# --- update changelog ---
# prepend this tag's release notes to top of CHANGELOG.md
tmpfileChangeLog=$(mktemp)
{
  cat "$tmpfileReleaseNotes"
  echo
  cat CHANGELOG.md
} > "$tmpfileChangeLog"
mv "$tmpfileChangeLog" CHANGELOG.md
git add CHANGELOG.md

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
git tag "$tag" -F "$tmpfileReleaseNotes"

# -- push --
git push origin master
git push origin "$tag"

# -- create a release, if `hub` is available --
if command -v hub >/dev/null 2>&1; then
  echo "hub is available, creating a release"
  { echo "$tag"; echo; git tag -l --format='%(contents)' "$tag"; } | hub release create -f - "$tag"
else
  echo "hub not found, no release created."
fi

# --- cleanup tag notes file ---
rm "$tmpfileReleaseNotes"

echo "Done: ${tag}"