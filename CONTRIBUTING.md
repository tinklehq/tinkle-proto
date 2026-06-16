# Contributing to tinkle-proto

## Source of truth

The `.proto` files under `tinkle/v1/` are auto-mirrored from
[`tinklehq/tinkle-server`](https://github.com/tinklehq/tinkle-server).
Do not edit them in this repository — your changes will be
overwritten on the next mirror sync. Open a PR against
`tinklehq/tinkle-server` instead.

## How a proto change flows to consumers

1. Edit `tinkle/v1/*.proto` in `tinklehq/tinkle-server`.
2. PR merged → `proto-publish.yml` mirror pushes the new protos
   to `tinklehq/tinkle-proto:main`.
3. **No follow-up PR is required here.** The PR to `tinkle-server`
   is enough; CI on this repo will regenerate the bindings
   against the new protos in `ci.yml` and verify they build and
   test cleanly. There is no generated code to commit.
4. The next `feat:` or `fix:` PR (with a releasable conventional
   commit) will cause release-please to open a Release PR per
   language; merging those cuts tags and `release.yml` publishes
   the regenerated bindings to `release/<component>` branches.

## Local validation

From the repo root:

```bash
buf format -d
buf lint
buf breaking --against ".git#branch=origin/main"
buf generate
# Generated files (go/tinkle/, elixir/lib/tinklev1*.ex) are not
# committed; they're fine to leave in your working tree or clean
# up with `git clean -fdx` if you prefer.
(cd go && go mod tidy && go build ./... && go vet ./...)
(cd rs  && cargo build --locked && cargo test --locked)
(cd elixir && mix deps.get && mix compile --warnings-as-errors && mix test)
```

These run in `ci.yml` on every PR + push to `main`.

## Conventional Commits

Releases are driven by [Conventional Commits](https://www.conventionalcommits.org/).
Use the standard prefixes so release-please can pick up the right
bump type per language:

| Prefix              | SemVer bump | Notes                                      |
|---------------------|-------------|--------------------------------------------|
| `feat:`             | MINOR       | New RPC, new message, new field            |
| `fix:`              | PATCH       | Behavior-preserving bug fix                |
| `feat!:` / `BREAKING CHANGE:` | MAJOR | Reserved for `tinkle/v2/`; do not use in `v1` |
| `perf:`             | PATCH       | Performance improvement                    |
| `refactor:`         | — (hidden)  | Internal refactor; no release entry        |
| `chore:` / `build:` / `ci:` / `docs:` / `style:` / `test:` | — (hidden) | Never trigger a release |

Hidden types are marked as such in `release-please-config.json`
and won't accumulate in a Release PR.

## Cutting a release

1. **Don't push a tag manually.** Release-please manages tags.
2. After enough releasable commits (`feat:`/`fix:`/`perf:`) have
   landed on `main`, release-please has already opened or updated
   a Release PR per language. The PR title looks like
   `chore: release X.Y.Z` (Go), `chore: release rust: X.Y.Z`
   (Rust), or `chore: release elixir: X.Y.Z`.
3. Review the PR — it updates:
   - `go/version.go` (`const Version = "X.Y.Z"`)
   - `rs/Cargo.toml` (`version = "X.Y.Z"`)
   - `elixir/mix.exs` (`version: "X.Y.Z"`)
   - `<component>/CHANGELOG.md`
   - `.release-please-manifest.json`
4. Merge the Release PR. release-please will:
   - Tag the merge commit on `main` with `<component>/vX.Y.Z`.
   - Create a GitHub Release.
5. The tag push triggers `release.yml` for post-tag verification
   and publish:
   - Regenerate from protos at the tagged commit.
   - Build and test the binding.
   - Force-push a `release/<component>` branch with the generated
     code.
   - Force-move the tag to the tip of `release/<component>`.
6. Consumers now `go get`/`cargo add`/`mix deps.get` from the tag
   and get a commit that contains the generated code.

You can land multiple Release PRs back-to-back (Go, then Rust, then
Elixir) — release-please keeps them independent.

## Hotfixing a release

To force a specific version (e.g. cutting a `1.2.4` patch release
without any new commits), use the bootstrap script:

```bash
bin/release-please-bump.sh 1.2.4
```

The script does the safety checks (on `main`, working tree clean,
in sync with `origin/main`) and pushes an empty commit with a
`Release-As: 1.2.4` trailer. release-please picks this up on its
next run and opens a Release PR at the requested version.

The same script handles bootstrap releases (e.g. `1.0.0` for the
first release of a new major) and major version transitions
(e.g. `2.0.0`). See `AGENTS.md` → "Forcing a specific release
version" for when to use it.

## Common tasks

| Task | Where to make the change |
|---|---|
| Add/change an RPC | `tinklehq/tinkle-server` (the proto source) — no follow-up PR here |
| Change Go module path | `go/go.mod` + `buf.gen.yaml` (`go_package_prefix` override) |
| Change Rust dependency versions | `rs/Cargo.toml` |
| Change Elixir package metadata | `elixir/mix.exs` |
| Add a new language | new directory at root + `buf.gen.yaml` entry + `release-please-config.json` `packages` entry + new `release-branch` mapping in `release.yml` |
| Adjust release-please config | `release-please-config.json` (and `.release-please-manifest.json` for initial version) |
| Add a new tool to the proto-source CI | `.github/workflows/ci.yml` (or a new file in `.github/workflows/`) |
