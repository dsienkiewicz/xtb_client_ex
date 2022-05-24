defmodule XtbClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :xtb_client_ex,
      name: "XtbClient",
      version: "0.1.1",
      elixir: "~> 1.12",
      description: "Elixir client for the XTB trading platform",
      source_url: "https://github.com/dsienkiewicz/xtb_client_ex",
      start_permanent: Mix.env() == :prod,
      package: package(),
      aliases: aliases(),
      deps: deps(),
      docs: docs()
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
      {:websockex, "~> 0.4.3"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:dotenvy, "~> 0.6.0", only: [:dev, :test]}
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
