defmodule XtbClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :xtb_client_ex,
      name: "XtbClient",
      version: "0.1.1",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Elixir client for the XTB trading platform",
      source_url: "https://github.com/dsienkiewicz/xtb_client_ex",
      start_permanent: Mix.env() == :prod,
      package: package(),
      aliases: aliases(),
      dialyzer: dialyzer(),
      deps: deps(),
      docs: docs()
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix, :ex_unit],
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {XtbClient.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.3"},
      {:websockex, "~> 0.4.3"},

      # Dev & test only
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:dotenvy, "~> 0.6.0", only: [:dev, :test]},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Daniel Sienkiewicz"],
      links: %{"GitHub" => "https://github.com/dsienkiewicz/xtb_client_ex"}
    }
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme"
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
      "tests.integration": ["test --color"]
    ]
  end
end
