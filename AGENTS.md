# AGENTS

This file is the entrypoint for AI coding agents working in this
repository. Read it fully before making any non-trivial change.

## TL;DR

- **`tinklehq/tinkle-proto`** is the source of truth for the
  `tinkle.v1` Protobuf contract. The repo contains the `.proto`
  files and Buf config only.
- The schema is published to the Buf Schema Registry at
  **`buf.build/tinklecorp/tinkle-proto`** (public). The BSR
  generates and serves **Go** and **Rust** SDKs to consumers; no
  language-specific code lives in this repo.
- The `.proto` files are mirrored from
  [`tinklehq/tinkle-server`](https://github.com/tinklehq/tinkle-server).
  Do not edit them here.
- **No release-please, no per-language tags, no generated code in
  the tree.** Bump a version on the BSR by pushing a new commit;
  consumers update via `go get @latest` or `cargo add --registry buf`.

## Architecture

```
tinklehq/tinkle-proto (this repo)    proto source + Buf config
├── tinkle/v1/*.proto                proto source (mirror of tinkle-server)
├── buf.yaml                         v2 single-module workspace
│                                    name: buf.build/tinklecorp/tinkle-proto
├── buf.lock                         generated
├── LICENSE                          required at module root for pkg.go.dev
├── README.md
├── .github/workflows/buf-ci.yaml    bufbuild/buf-action:
│                                      build/lint/format/breaking/push
└── AGENTS.md
```

The BSR takes care of everything else: published module, generated
SDKs, version history, generated documentation, and dependency
resolution. See <https://buf.build/tinklecorp/tinkle-proto> for the
live state.

## Consumer dependencies

| Language | Command |
|----------|---------|
| Go       | `go get buf.build/gen/go/tinklecorp/tinkle-proto/protocolbuffers/go` |
| Go (gRPC) | `go get buf.build/gen/go/tinklecorp/tinkle-proto/grpc/go` |
| Rust     | `cargo add --registry buf tinklecorp_tinkle-proto_bufbuild_community_tonic-prost` |

Versions are `{plugin-version}-{module-commit-timestamp}-{module-commit-id}.{plugin-revision}`
(e.g. `v1.36.11-20260617120000-abc123def456.1`). Pin with
`@vX.Y.Z-…`, `@<commit-id>`, or `@<label>`.

## Conventions for agents

1. **Do not edit `.proto` files** under `tinkle/v1/`. Edit them in
   `tinklehq/tinkle-server`; the mirror will sync.
2. **`buf push` is automatic on merge to `main`.** The `buf-ci.yaml`
   workflow uses `bufbuild/buf-action@v1`; on push to `main` it
   publishes every named module in the workspace to the BSR with
   the matching Git metadata.
3. **`BUF_TOKEN` secret is required.** A BSR API token for the
   `tinklecorp` org must be configured as a repository secret
   (Settings → Secrets and variables → Actions) before the first
   merge to `main`, otherwise the initial `buf push` will fail and
   the BSR module will not be created. The action auto-creates the
   BSR repo on first push; `push_create_visibility: public` makes
   that explicit.
4. **Lint before pushing.** Run `buf format -d` and `buf lint`
   locally; the `buf-ci.yaml` action will run them on every PR and
   fail the build on findings.
5. **Breaking changes are blocked by `buf breaking`** in CI (the
   `breaking: FILE` category from `buf.yaml`). For intentional
   breaks, add a `buf skip breaking` label to the PR (Issues →
   Labels in the repo settings) — the action checks for the label
   and skips the breaking step. For permanent breaks, add a new
   package path (`tinkle/v2/`) rather than mutating `tinkle/v1/`.
6. **No `buf generate`, no `buf.gen.yaml`.** Code generation
   happens on the BSR. A `buf.gen.yaml` only exists if you need
   to run `buf generate` against a third-party plugin locally;
   in this repo, there is none.

## When asked to "add a new RPC"

1. Open a PR in `tinklehq/tinkle-server` editing the relevant
   `tinkle/v1/*.proto`.
2. Once merged, the mirror syncs the change into
   `tinklehq/tinkle-proto:main`.
3. Open a PR here. The buf-ci action will run `format`, `lint`,
   `breaking`, and post a PR comment summarizing the check results.
4. Merge to `main`. The action runs `buf push`, which publishes a
   new commit to the BSR. The BSR serves the updated Go and Rust
   SDKs lazily — consumers pick them up with `go get @latest` or
   the next `cargo add` (Rust SDKs are generated eagerly, so a new
   crate version is produced immediately on push to the default
   label after the initial `cargo add`).

## When asked to "fix generated code"

Don't try to fix generated code in this repo — there is no
generated code in this repo. Fix the proto definition upstream in
`tinklehq/tinkle-server`. Once the mirror syncs, open a PR here;
`buf-ci` will publish the new schema to the BSR, and consumers
will pick up the regenerated SDKs on their next `go get`/`cargo
add`.

## Local validation

```bash
buf format -d
buf lint
buf breaking --against ".git#branch=origin/main"
buf build
```

These are the same checks the `buf-ci.yaml` action runs on every
PR. There is no local `buf generate` step.

## CI workflow

`.github/workflows/buf-ci.yaml` runs `bufbuild/buf-action@v1`,
which on every PR runs `build`, `lint`, `format`, and `breaking`,
and on every push to `main` also runs `buf push` (publishing to
the BSR). On a branch delete, the action archives the matching
BSR label. The action posts a PR summary comment keyed on
`<workflow>:<job>`.

## BSR resource

- Module: <https://buf.build/tinklecorp/tinkle-proto>
- Generated SDKs: <https://buf.build/tinklecorp/tinkle-proto/sdks>
- Documentation: <https://buf.build/tinklecorp/tinkle-proto/docs>
