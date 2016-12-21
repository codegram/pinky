defmodule Pinky.Mixfile do
  use Mix.Project

  def project do
    [app: :pinky,
     version: "0.1.0",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     name: "Pinky",
     source_url: "https://github.com/codegram/pinky",
     homepage_url: "https://codegram.github.io/pinky",
     docs: [main: "readme",
            extras: ["README.md"]],
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    []
  end

  defp deps do
    [{:ex_doc, "~> 0.14", only: :dev}]
  end

  defp description do
    """
    A promise library for Elixir.
    """
  end

  defp package do
    [name: :pinky,
     files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Txus Bach"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/codegram/pinky",
              "Docs"=> "http://hexdocs.pm/pinky"}]
  end
end
