defmodule TinkleProto.MixProject do
  use Mix.Project

  def project do
    [
      app: :tinkle_proto,
      version: "2.0.0",
      elixir: "~> 1.15",
      elixirc_paths: ["lib"],
      deps: deps(),
      package: package(),
      description: "Elixir/OTP gRPC client bindings for the Tinkle Messenger v1 API",
      source_url: "https://github.com/tinklehq/tinkle-proto"
    ]
  end

  def application, do: [extra_applications: [:logger, :inets, :ssl]]

  defp deps do
    [
      {:protobuf, "~> 0.17"},
      {:grpc, "~> 0.11"}
    ]
  end

  defp package do
    [
      name: :tinkle_proto,
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/tinklehq/tinkle-proto"}
    ]
  end
end
