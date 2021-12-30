defmodule XtbClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :xtb_client_ex,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {XtbClient.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.3"},
      {:websockex, "~> 0.4.3"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "tests.all": ["tests.unit", "tests.integration"],
      "tests.unit": ["test --color"],
      "tests.integration": [
        "source .env.dev",
        "test --color"
      ]
    ]
  end
end
