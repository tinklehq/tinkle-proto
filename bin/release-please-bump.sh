#!/usr/bin/env bash
# bin/release-please-bump.sh
#
# Force release-please to cut a specific version, bypassing the
# conventional-commits-derived SemVer computation.
#
# Two modes are supported:
#
#   1. Bootstrapping or cross-major bumps (default mode)
#      Push an empty commit with a `Release-As: X.Y.Z` trailer.
#      release-please will open Release PRs for every package
#      that has releasable conventional commits since the last
#      release. Use this for the initial 1.0.0 / 2.0.0 / ...
#      release, or for hotfixing a single version across all
#      packages at once.
#
#        bin/release-please-bump.sh 1.0.0
#        bin/release-please-bump.sh 2.0.0 "feat: tinkle/v2 proto migration"
#
#   2. Per-component manifest edit (--component / --to)
#      Directly edit .release-please-manifest.json to set a
#      specific package's current version, commit the change,
#      and push. release-please will then open a release PR
#      for that package (when there are releasable commits) at
#      the new version. Use this for ongoing multi-major
#      maintenance where you want to bump v1 to 1.5.0 without
#      touching v2, or vice versa.
#
#        bin/release-please-bump.sh --component go --to 1.5.0
#        bin/release-please-bump.sh --component go-v2 --to 2.0.0 \
#          --message "feat: tinkle/v2 proto migration"
#
# How it works (mode 1):
#   release-please reads the body of every commit on the target
#   branch since the last release. A `Release-As: X.Y.Z` trailer
#   in the commit body forces the next release for that package
#   to be at X.Y.Z, regardless of conventional-commit history.
#
# How it works (mode 2):
#   We patch .release-please-manifest.json so that the named
#   package's "current version" becomes <to>. release-please
#   reads the manifest on its next run; the difference between
#   the manifest version and the new computed version is what
#   drives the Release PR. (release-please only opens a Release
#   PR if the package has releasable conventional commits since
#   its last release; bumping the manifest alone is not enough
#   to force a release if there are no releasable commits.)
#
# When to use:
#   - Bootstrap (first release of a new major):
#       bin/release-please-bump.sh 1.0.0
#   - Major version transition (e.g. tinkle/v1/ -> tinkle/v2/):
#       bin/release-please-bump.sh 2.0.0
#   - Multi-major ongoing maintenance (bump one component only):
#       bin/release-please-bump.sh --component go --to 1.5.0
#   - Hotfix that wants to skip the next automatic SemVer bump
#     across all packages:
#       bin/release-please-bump.sh 1.2.5
#
# Notes:
#   - Must be run from the repo root on the default branch (main).
#   - Local git config must have push rights to origin.

set -euo pipefail

# --- argument parsing -------------------------------------------------------

USAGE="Usage:
  $0 <version> [commit-message]
  $0 --component <name> --to <version> [--message <msg>]"

VERSION=""
COMMIT_MSG=""
COMPONENT=""
TO_VERSION=""

if [[ $# -eq 0 ]]; then
  echo "$USAGE" >&2
  exit 1
fi

# Mode 2: --component / --to
if [[ "${1:-}" == "--component" || "${1:-}" == "-c" ]]; then
  if [[ $# -lt 4 ]]; then
    echo "$USAGE" >&2
    exit 1
  fi
  COMPONENT="$2"
  shift 2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --to)
        TO_VERSION="$2"
        shift 2
        ;;
      --message|-m)
        COMMIT_MSG="$2"
        shift 2
        ;;
      *)
        echo "::error:: unknown argument: $1" >&2
        echo "$USAGE" >&2
        exit 1
        ;;
    esac
  done

  if [[ -z "$COMPONENT" || -z "$TO_VERSION" ]]; then
    echo "$USAGE" >&2
    exit 1
  fi
else
  # Mode 1: positional <version> [commit-message]
  VERSION="$1"
  COMMIT_MSG="${2:-chore: bootstrap release ${VERSION}}"
fi

# --- validation ------------------------------------------------------------

validate_semver() {
  local v="$1"
  if ! [[ "$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
    echo "::error:: version must be SemVer (e.g. 1.0.0, 2.0.0-rc1): got '$v'" >&2
    exit 1
  fi
}

if [[ -n "$VERSION" ]]; then
  validate_semver "$VERSION"
fi
if [[ -n "$TO_VERSION" ]]; then
  validate_semver "$TO_VERSION"
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

# --- run --------------------------------------------------------------------

GIT_BOT_NAME="github-actions[bot]"
GIT_BOT_EMAIL="41898282+github-actions[bot]@users.noreply.github.com"

REPO_URL="$(git remote get-url origin | sed -E 's#.*github.com[:/]([^/]+)/([^/.]+)(\.git)?#\1/\2#')"

if [[ -n "$COMPONENT" ]]; then
  # --- mode 2: edit manifest ----------------------------------------------
  MANIFEST=".release-please-manifest.json"
  if [[ ! -f "$MANIFEST" ]]; then
    echo "::error:: manifest not found at $MANIFEST" >&2
    exit 1
  fi

  # Validate component exists in manifest.
  if ! grep -q "\"$COMPONENT\"" "$MANIFEST"; then
    echo "::error:: component '$COMPONENT' not found in $MANIFEST" >&2
    echo "Available components:" >&2
    grep -oE '"[a-zA-Z0-9_-]+":\s*"[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?"' "$MANIFEST" \
      | sed 's/^/  /' >&2
    exit 1
  fi

  # Sanity: bumping backwards would surprise users. Warn but allow.
  CURRENT_VERSION="$(grep -oE "\"$COMPONENT\":\s*\"[^\"]+\"" "$MANIFEST" \
    | grep -oE '"[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?"' | tr -d '"')"
  echo "Bumping $COMPONENT: ${CURRENT_VERSION} -> ${TO_VERSION}"

  DEFAULT_MSG="chore(${COMPONENT}): bump ${CURRENT_VERSION} -> ${TO_VERSION}"
  COMMIT_MSG="${COMMIT_MSG:-$DEFAULT_MSG}"

  # Patch the manifest in place. Use python so the JSON edit is
  # unambiguous regardless of whitespace / formatting.
  python3 - "$MANIFEST" "$COMPONENT" "$TO_VERSION" <<'PY'
import json, sys
path, comp, new_v = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    data = json.load(f)
if comp not in data:
    print(f"::error:: component {comp!r} not in manifest", file=sys.stderr)
    sys.exit(1)
data[comp] = new_v
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY

  git add "$MANIFEST"
  GIT_AUTHOR_NAME="$GIT_BOT_NAME" \
  GIT_AUTHOR_EMAIL="$GIT_BOT_EMAIL" \
  GIT_COMMITTER_NAME="$GIT_BOT_NAME" \
  GIT_COMMITTER_EMAIL="$GIT_BOT_EMAIL" \
  git commit -m "$COMMIT_MSG"

  git push origin HEAD

  echo
  echo "Done. Bumped $COMPONENT to $TO_VERSION in $MANIFEST."
  echo "release-please will run on the next push to main and"
  echo "open a Release PR for $COMPONENT (if it has releasable"
  echo "conventional commits since $CURRENT_VERSION)."
  echo
  echo "Watch the workflow:"
  echo "  https://github.com/${REPO_URL}/actions/workflows/release-please.yml"
else
  # --- mode 1: empty commit with Release-As trailer ---------------------
  echo "Pushing empty commit to force release-please to cut ${VERSION}..."
  GIT_AUTHOR_NAME="$GIT_BOT_NAME" \
  GIT_AUTHOR_EMAIL="$GIT_BOT_EMAIL" \
  GIT_COMMITTER_NAME="$GIT_BOT_NAME" \
  GIT_COMMITTER_EMAIL="$GIT_BOT_EMAIL" \
  git commit --allow-empty -m "$COMMIT_MSG" -m "Release-As: ${VERSION}"

  git push origin HEAD

  echo
  echo "Done. release-please will run on the next push to main and"
  echo "open Release PRs at ${VERSION} for each language binding that"
  echo "has releasable conventional commits since its last release."
  echo
  echo "Watch the workflow:"
  echo "  https://github.com/${REPO_URL}/actions/workflows/release-please.yml"
fi
