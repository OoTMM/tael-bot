defmodule TaelBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :tael_bot,
      version: "1.0.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TaelBot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dotenvy, "~> 1.1"},
      {:ecto_sqlite3, "~> 0.22.0"},
      {:jason, "~> 1.4"},
      {:tesla, "~> 1.16"},
      {:nostrum, "~> 0.10"},
    ]
  end
end
