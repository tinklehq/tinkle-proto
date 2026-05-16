# tinkle-proto

Public client gRPC API contracts for **Tinkle Messenger**.

> **Read-only mirror.** This repository is auto-published from
> [`tinklehq/tinkle-server`](https://github.com/tinklehq/tinkle-server)
> under `proto/tinkle/v1/`. **Do not edit files here directly** —
> changes will be overwritten on the next release.

## Layout

```
tinkle/v1/   # gRPC service contracts (account, auth, channels, ...)
buf.yaml     # buf lint/breaking config
```

## Versioning

Tags follow SemVer (`vMAJOR.MINOR.PATCH`) and are driven by
[Conventional Commits](https://www.conventionalcommits.org/) on the
source monorepo:

| Commit type            | Bump  |
|------------------------|-------|
| `feat!:` / `BREAKING CHANGE:` | major |
| `feat:`                  | minor |
| `fix:`                   | patch |

## Consumption (Rust / libtinkle)

```toml
# Cargo.toml
[dependencies]
tinkle-proto = { git = "ssh://git@github.com/tinklehq/tinkle-proto.git", tag = "v0.1.0" }
```

Or use `buf` directly:

```yaml
# buf.yaml
deps:
  - github.com/tinklehq/tinkle-proto:v0.1.0
```

## Source

- Source of truth: `proto/tinkle/v1/` in
  [`tinklehq/tinkle-server`](https://github.com/tinklehq/tinkle-server)
- Publish workflow:
  [`.github/workflows/proto-publish.yml`](https://github.com/tinklehq/tinkle-server/blob/main/.github/workflows/proto-publish.yml)
