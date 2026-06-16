# tinkle-proto (Elixir package)

Elixir/OTP gRPC client bindings for the `tinkle.v1` API contract.

The actual generated Elixir source (Protobuf messages + gRPC
service stubs) is produced by `buf generate` against the
`.proto` files in the parent repo **at release time**, then
committed to a `release/elixir` branch. Nothing generated is
committed on `main` — only `mix.exs` and other metadata live here.

## Usage

Add to your `mix.exs`:

```elixir
{:tinkle_proto, git: "https://github.com/tinklehq/tinkle-proto", tag: "elixir/v1.2.3"}
```

The tag points to a `release/elixir` branch commit that contains
the generated `lib/tinklev1_*.ex` modules.

## Regenerating (for maintainers)

Generated Elixir code is not produced on `main`. It is produced
at release time by `release.yml`. If you want to verify locally
that the build still works after editing protos or this package's
metadata, install the elixir escripts and run `buf generate`
from the repo root, then:

```bash
mix deps.get
mix compile --warnings-as-errors
mix test
```
