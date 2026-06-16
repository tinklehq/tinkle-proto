# tinkle-proto (Rust crate)

Rust gRPC client bindings for the `tinkle.v1` API contract.

The actual generated Rust source (prost message types + tonic gRPC
stubs) is produced by the `build.rs` script in this directory at
**consumer build time** — it runs `tonic-build` against the
`.proto` files in the parent repo. Nothing generated is committed.

## Usage

Add to your `Cargo.toml`:

```toml
[dependencies]
tinkle-proto = { git = "https://github.com/tinklehq/tinkle-proto", tag = "rust/v1.2.3" }
```

The tag points to a `release/rust` branch commit that contains the
generated sources. Cargo reads them via `tonic::include_proto!`
from this crate's `src/lib.rs`.

## Regenerating (for maintainers)

The `build.rs` in this directory regenerates the Rust source at
build time. No regeneration is needed when changing protos — the
next release will pick up the change automatically.

If you want to verify locally that the build still works after
editing protos or this crate's metadata:

```bash
cargo build --locked
cargo test --locked
```
