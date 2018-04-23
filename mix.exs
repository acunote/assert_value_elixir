defmodule AssertValue.Mixfile do
  use Mix.Project

  def project do
    [app: :assert_value,
     version: "0.8.4",
     elixir: "~> 1.5",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [ applications: [],
      mod: {AssertValue.App, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    "ExUnit's assert on steroids that writes and updates tests for you"
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Gleb Arshinov", "Serge Smetana"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/assert-value/assert_value_elixir"}]
  end
end
