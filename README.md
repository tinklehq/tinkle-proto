# tinkle-proto

Public client gRPC API contracts for **Tinkle Messenger**.

> **Read-only mirror.** This repository is auto-published from
> [`tinklehq/tinkle-server`](https://github.com/tinklehq/tinkle-server)
> under `proto/tinkle/`. **Do not edit files here directly** —
> changes will be overwritten on the next publish.

## Versioning

API versioning is **path-based** (gRPC / buf convention):

- `tinkle/v1/` — current stable package
- `tinkle/v2/` — added side-by-side when a breaking change ships
- Migration is by changing your import path, not by version tag

There are **no SemVer tags** on this repository. Pin consumers to a
**commit SHA** for reproducibility.

## Layout

```
          tinkle/v1/   # `tinkle.v1` package (gRPC service contracts)
          buf.yaml     # buf lint/breaking config
```

## Consumption

### Rust (libtinkle, via `tonic-build`)

```toml
[dependencies]
tinkle-proto = { git = "ssh://git@github.com/tinklehq/tinkle-proto.git", rev = "<COMMIT_SHA>" }
```

### Buf

```yaml
# buf.yaml in your client repo
deps:
  - github.com/tinklehq/tinkle-proto:<COMMIT_SHA>
```

Replace `<COMMIT_SHA>` with the head of `main` (or any prior
mirror commit you want to pin to).

## Source

- Source of truth: `proto/tinkle/` in
  [`tinklehq/tinkle-server`](https://github.com/tinklehq/tinkle-server)
- Publish workflow:
  [`.github/workflows/proto-publish.yml`](https://github.com/tinklehq/tinkle-server/blob/main/.github/workflows/proto-publish.yml)
