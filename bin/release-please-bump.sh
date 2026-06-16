#!/usr/bin/env bash
# bin/release-please-bump.sh
#
# Force release-please to cut a specific version, bypassing the
# conventional-commits-derived SemVer computation.
#
# How it works:
#   release-please reads the body of every commit on the target
#   branch since the last release. A `Release-As: X.Y.Z` trailer
#   in the commit body forces the next release for every package
#   that has releasable conventional commits since the last release.
#   We push an empty commit with that trailer.
#
# Usage:
#   bin/release-please-bump.sh <version> [commit-message]
#
# Examples:
#   bin/release-please-bump.sh 1.0.0
#   bin/release-please-bump.sh 2.0.0 "feat: tinkle/v2 proto migration"
#   bin/release-please-bump.sh 1.2.5 "fix(go): hotfix release"
#
# When to use:
#   - Bootstrap (first release of a repo):
#       bin/release-please-bump.sh 1.0.0
#   - Major version transition:
#       bin/release-please-bump.sh 2.0.0
#   - Hotfix that wants to skip the next automatic SemVer bump:
#       bin/release-please-bump.sh 1.2.5
#
# When NOT to use:
#   - Routine `feat:` / `fix:` / `perf:` releases — let release-please
#     compute the next version from the commit log.
#   - Changes you want to record as `feat`/`fix` in the changelog —
#     use real commits, not `Release-As:` trailers, for those.
#
# Notes:
#   - Must be run from the repo root on the default branch (main).
#   - Local git config must have push rights to origin.
#   - The version must be SemVer (X.Y.Z or X.Y.Z-prerelease).

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <version> [commit-message]" >&2
  echo "  e.g. $0 1.0.0" >&2
  echo "  e.g. $0 2.0.0 \"feat: tinkle/v2 proto migration\"" >&2
  exit 1
fi

VERSION="$1"
COMMIT_MSG="${2:-chore: bootstrap release ${VERSION}}"

# Validate version is SemVer.
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
  echo "::error:: version must be SemVer (e.g. 1.0.0, 2.0.0-rc1): got '$VERSION'" >&2
  exit 1
fi

# Sanity check: must be on main and clean.
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "::error:: must be on 'main', currently on '$CURRENT_BRANCH'" >&2
  exit 1
fi

if ! git diff --quiet HEAD; then
  echo "::error:: working tree has uncommitted changes; commit or stash first" >&2
  exit 1
fi

if ! git diff --cached --quiet HEAD; then
  echo "::error:: index has staged changes; commit or reset first" >&2
  exit 1
fi

# Make sure we're up to date with origin/main.
git fetch origin main
LOCAL="$(git rev-parse HEAD)"
REMOTE="$(git rev-parse origin/main)"
if [[ "$LOCAL" != "$REMOTE" ]]; then
  echo "::error:: local main ($LOCAL) is not at origin/main ($REMOTE); pull or push first" >&2
  exit 1
fi

# Push the empty commit with the Release-As trailer.
echo "Pushing empty commit to force release-please to cut ${VERSION}..."

GIT_AUTHOR_NAME="github-actions[bot]" \
GIT_AUTHOR_EMAIL="41898282+github-actions[bot]@users.noreply.github.com" \
GIT_COMMITTER_NAME="github-actions[bot]" \
GIT_COMMITTER_EMAIL="41898282+github-actions[bot]@users.noreply.github.com" \
git commit --allow-empty -m "$COMMIT_MSG" -m "Release-As: ${VERSION}"

git push origin HEAD

echo
echo "Done. release-please will run on the next push to main and"
echo "open Release PRs at ${VERSION} for each language binding that"
echo "has releasable conventional commits since its last release."
echo
REPO_URL="$(git remote get-url origin | sed -E 's#.*github.com[:/]([^/]+)/([^/.]+)(\.git)?#\1/\2#')"
echo "Watch the workflow:"
echo "  https://github.com/${REPO_URL}/actions/workflows/release-please.yml"
