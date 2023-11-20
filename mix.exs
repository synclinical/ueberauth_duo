defmodule Ueberauth.Duo.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/synclinical/ueberauth_duo"

  def project do
    [
      app: :ueberauth_duo,
      name: "Ueberauth Duo",
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ueberauth, :oauth2]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ueberauth, "~> 0.10"},
      {:oauth2, "~> 2.0"},
      {:credo, "~> 1.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
  
  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package do
    [
      description: "An Ueberauth strategy for using Cisco Duo to authenticate your users.",
      files: ["CHANGELOG.md", "lib", "mix.exs", "README.md", "LICENSE.md", "CONTRIBUTING.md"],
      licenses: ["MIT"],
      links: %{
        Changelog: "https://hexdocs.pm/ueberauth_duo/changelog.html",
        GitHub: @source_url
      }
    ]
  end
end
