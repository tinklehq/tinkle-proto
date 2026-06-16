# Changelog

This repository (`tinklehq/tinkle-proto`) is the monorepo for the
`tinkle.v1` gRPC contract and per-language binding metadata
(`go/go.mod`, `rs/Cargo.toml`, `elixir/mix.exs`, etc.).

**Generated code is not committed to `main`.** It is regenerated at
release time by `release.yml` and committed to per-language
`release/<component>` branches, which is what the git tag points
to. Releases are managed by **release-please** (manifest config
with `separate-pull-requests: true`) and use **strict SemVer**
with `MAJOR` tracking the proto package version
(`tinkle/v1` → major=1):

- `go/vX.Y.Z`     — Go bindings
- `rust/vX.Y.Z`   — Rust crate
- `elixir/vX.Y.Z` — Elixir package

Tags are cut automatically when a release-please Release PR is
merged; `release.yml` then regenerates + builds + tests the
binding and force-moves the tag to a `release/<component>` branch
with the generated code. Bumps are driven by
[Conventional Commits](https://www.conventionalcommits.org/):
`feat:` → minor, `fix:` → patch, `feat!:` / `BREAKING CHANGE:` → major.

## Unreleased

- Initial monorepo migration: protos and per-language binding
  metadata (`go/`, `rs/`, `elixir/`) now live at the root of this
  repo. Generated code is not committed; it's produced at release
  time and committed to `release/<component>` branches.
- Adopted release-please (mirroring `tinklehq/tinkle-server`).
  Versions are SemVer and managed per-language; no version is
  bumped on PR merge to `main`.
- Adopted the release-branch model: `release.yml` force-pushes a
  `release/<component>` branch with the generated code and
  force-moves the tag there, so all three languages are served
  by git tag only.
