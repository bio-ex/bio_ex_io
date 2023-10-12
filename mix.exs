defmodule Bio.IO.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/bio-ex/bio_ex_io"

  def project do
    [
      app: :bio_ex_io,
      description: describe(),
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "bio_ex_io",
      package: package(),
      aliases: aliases(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :xmerl]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:benchee, "~> 1.0", only: :dev},
      # integration test dependency
      {:bio_ex_sequence, "~> 0.1", only: :test}
    ]
  end

  defp package() do
    [
      licenses: ["BSD-3-Clause"],
      links: %{"GitHub" => "https://github.com/bio-ex/bio_ex_io"}
    ]
  end

  defp describe() do
    "Input/Output for common bioinformatics file types"
  end

  defp aliases do
    []
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]

  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: extras(),
      extra_section: "GUIDES",
      groups_for_extras: groups_for_extras(),
      groups_for_functions: [
        group_for_function("none")
      ],
      groups_for_modules: [
        "File Types": [
          Bio.IO.Fasta,
          Bio.IO.FastQ,
          Bio.IO.QualityScore,
          Bio.IO.SnapGene
        ]
      ]
    ]
  end

  def extras() do
    [
      "guides/howtos/use_xml_and_xpath.md"
    ]
  end

  defp group_for_function(group), do: {String.to_atom(group), &(&1[:group] == group)}

  defp groups_for_extras do
    [
      "How-To's": ~r/guides\/howtos\/.?/,
      Cheatsheets: ~r/cheatsheets\/.?/
    ]
  end
end
