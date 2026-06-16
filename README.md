# tinkle-proto

Source of truth for the `tinkle.v1` gRPC contract and per-language
binding metadata. This is a monorepo: protos and language binding
metadata live side by side at the root. **Generated code is not
committed to `main`** — it is regenerated at release time and
committed to per-language `release/<component>` branches, which is
what the git tag points to.

The proto files are auto-mirrored from
[`tinklehq/tinkle-server`](https://github.com/tinklehq/tinkle-server);
this repo is the source of truth for generation.

> **Do not edit `tinkle/v1/*.proto` in this repo.** Open a PR in
> `tinklehq/tinkle-server` instead; the next mirror sync will
> pull the change here.

## Architecture

```
tinklehq/tinkle-proto/                 ← monorepo (this repo)
├── tinkle/v1/*.proto                  proto source (read-only mirror)
├── go/                                Go module metadata (go.mod, version.go)
├── rs/                                Rust crate metadata (Cargo.toml, build.rs)
├── elixir/                            Elixir package metadata (mix.exs)
├── buf.yaml + buf.gen.yaml            generation config
├── release-please-config.json         release-please manifest config
├── .release-please-manifest.json      per-language version tracking
└── .github/workflows/
    ├── ci.yml                         lint, breaking, per-language regen + build + test
    ├── release-please.yml             on push to main → open/update Release PRs
    └── release.yml                    on tag push → regen + build + test + push release branch
```

Per-language `release/<component>` branches (force-pushed by
`release.yml` on each release) hold the regenerated binding for
that language. The git tag `<component>/vX.Y.Z` points to the tip
of that branch, so consumers fetch a commit that contains the
generated code:

```
main (proto source + metadata)
   │
   ▼  release-please merges a Release PR
release-please cuts <component>/vX.Y.Z on main
   │
   ▼  tag push triggers release.yml
release.yml:
   1. regenerate from protos at the tagged commit
   2. build & test
   3. force-push release/<component> branch with the generated code
   4. force-move the tag to that branch's tip
   │
   ▼
Consumers: go get / cargo add / mix deps.get → tag resolves to release/<component>
```

## Consuming the bindings

Versions are managed by **release-please** and follow strict
**SemVer** with `MAJOR` tracking the proto package version
(`tinkle/v1` → major=1):

| Language | Add to your project |
|---|---|
| Go | `go get github.com/tinklehq/tinkle-proto/go@go/vX.Y.Z` |
| Rust | `tinkle-proto = { git = "https://github.com/tinklehq/tinkle-proto", tag = "rust/vX.Y.Z" }` |
| Elixir | `{:tinkle_proto, git: "https://github.com/tinklehq/tinkle-proto", tag: "elixir/vX.Y.Z"}` |

Versions are bumped by [Conventional Commits](https://www.conventionalcommits.org/):
`feat:` → minor, `fix:` → patch, `feat!:` → major. When `tinkle/v2/`
ships, all three bump to `v2.Y.Z` under their prefixes.

## CI

- **`.github/workflows/ci.yml`** — on every PR + push to `main`:
  `buf format`, `buf lint`, `buf breaking`, `buf generate` (smoke
  test), then per-language `regen + build + test` for Go, Rust,
  and Elixir. No generated code is committed, so no drift check.
- **`.github/workflows/release-please.yml`** — on push to `main`:
  release-please opens or updates one Release PR per language.
  **No version is bumped on PR merge to main** — only when a human
  merges a Release PR does release-please cut the tag and GitHub
  Release.
- **`.github/workflows/release.yml`** — on push of a per-language
  tag (`go/v*`, `rust/v*`, `elixir/v*`): regenerates from protos,
  builds + tests, then force-pushes a `release/<component>` branch
  with the generated code and force-moves the tag to its tip.

There is **no** auto-publish to a registry; consumers depend on
each language binding via git url + a per-language tag (which
resolves to a `release/<component>` branch commit).

## Source

- Source of truth for protos:
  [`tinklehq/tinkle-server`](https://github.com/tinklehq/tinkle-server)
- Mirror workflow:
  [`tinklehq/tinkle-server` → `tinklehq/tinkle-proto`](https://github.com/tinklehq/tinkle-server/blob/main/.github/workflows/proto-publish.yml)
