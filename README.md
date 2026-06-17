# tinkle-proto

Source of truth for the `tinkle.v1` Protobuf contract. The schema is
published to the [Buf Schema Registry](https://buf.build/tinklecorp/tinkle-proto)
(public), which generates and serves **Go** and **Rust** SDKs to
consumers. This repo contains only the proto source and Buf config.

The proto files are auto-mirrored from
[`tinklehq/tinkle-server`](https://github.com/tinklehq/tinkle-server);
this repo is the source of truth for generation.

> **Do not edit `tinkle/v1/*.proto` in this repo.** Open a PR in
> `tinklehq/tinkle-server` instead; the next mirror sync will pull
> the change here.

## Architecture

```
tinklehq/tinkle-proto/                 ← proto source + Buf config
├── tinkle/v1/*.proto                  proto source (read-only mirror)
├── buf.yaml                           v2 workspace; module is published
│                                      to buf.build/tinklecorp/tinkle-proto
├── buf.lock                           generated
├── LICENSE                            at module root (required for pkg.go.dev)
├── README.md
└── .github/workflows/buf-ci.yaml      bufbuild/buf-action:
                                         build/lint/format/breaking/push
```

No per-language directories, no `buf.gen.yaml`, no generated code in
the tree. The BSR owns the generated Go and Rust artifacts.

```
main (proto source + Buf config)
   │
   ▼  CI: buf push on every merge to main
buf.build/tinklecorp/tinkle-proto (public)
   │
   ▼  consumer reads
go get buf.build/gen/go/tinklecorp/tinkle-proto/{protocolbuffers,grpc}/go
cargo add --registry buf tinklecorp_tinkle-proto_bufbuild_community_tonic-prost
```

## Consuming the bindings

The BSR auto-versions each push. SDK versions are
`{plugin-version}-{module-commit-timestamp}-{module-commit-id}.{plugin-revision}`
(e.g. `v1.36.11-20260617120000-abc123def456.1`). Pin with
`@vX.Y.Z-…`, `@<commit-id>`, or `@<label>`.

### Go

```bash
go get buf.build/gen/go/tinklecorp/tinkle-proto/protocolbuffers/go@latest
go get buf.build/gen/go/tinklecorp/tinkle-proto/grpc/go@latest
```

```go
import (
    tinklev1   "buf.build/gen/go/tinklecorp/tinkle-proto/protocolbuffers/go/tinkle/v1"
    tinklegrpc "buf.build/gen/go/tinklecorp/tinkle-proto/grpc/go/tinkle/v1;tinklev1grpc"
)
```

The two modules must be pinned to the same module commit
(the timestamp and short-id segments) so the message types and the
gRPC stubs stay in sync.

### Rust

Add the `buf` Cargo registry to `.cargo/config.toml`:

```toml
[registries.buf]
index = "sparse+https://buf.build/gen/cargo/"
credential-provider = "cargo:token"
```

Then add the crate:

```bash
cargo add --registry buf tinklecorp_tinkle-proto_bufbuild_community_tonic-prost
```

> **First-`cargo-add` priming.** Rust SDKs are generated eagerly on
> the BSR (Cargo needs a checksum for every version). The first
> `cargo add` against this module triggers the initial generation;
> every subsequent push to `main` produces a new crate version
> automatically.

### Other ecosystems

The BSR also serves TypeScript/JavaScript, Python, Java/Kotlin, and
Swift SDKs against the same module — see
[buf.build/tinklecorp/tinkle-proto/sdks](https://buf.build/tinklecorp/tinkle-proto/sdks).

## CI

`.github/workflows/buf-ci.yaml` runs `bufbuild/buf-action@v1`. On
every PR to `main` it runs `build`, `lint`, `format`, and `breaking`,
and posts a summary comment. On every push to `main` it also runs
`buf push`, which publishes the named module to the BSR. On a branch
delete it archives the matching BSR label.

### Required secret

`BUF_TOKEN` — a BSR API token for the `tinklecorp` org, configured
as a repository secret (Settings → Secrets and variables → Actions).
The action auto-creates the BSR repo on first push; `push_create_visibility: public`
is set explicitly. Without `BUF_TOKEN`, the first push fails and
the BSR module is not created.

### Breaking changes

`buf breaking` runs on every PR with the `FILE` category (the
strictest — catches anything that would break generated code). For
intentional breaks, add the `buf skip breaking` label to the PR
(Issues → Labels in the repo settings); the action checks for the
label and skips the breaking step. For permanent breaks, add a new
package path (`tinkle/v2/`) rather than mutating `tinkle/v1/`.

## Local validation

```bash
buf format -d
buf lint
buf breaking --against ".git#branch=origin/main"
buf build
```

These are the same checks the buf-ci action runs on every PR. There
is no local `buf generate` step — code generation happens on the
BSR.

## BSR resource

- Module: <https://buf.build/tinklecorp/tinkle-proto>
- Generated SDKs: <https://buf.build/tinklecorp/tinkle-proto/sdks>
- Documentation: <https://buf.build/tinklecorp/tinkle-proto/docs>

## Source

- Source of truth for protos:
  [`tinklehq/tinkle-server`](https://github.com/tinklehq/tinkle-server)
- Mirror workflow:
  [`tinklehq/tinkle-server` → `tinklehq/tinkle-proto`](https://github.com/tinklehq/tinkle-server/blob/main/.github/workflows/proto-publish.yml)
