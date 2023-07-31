defmodule Bio.QualityScore do
  @moduledoc """
  A struct representing the quality score of a FASTQ file.

  ``` elixir
  %QualityScore{
    scoring_characters: binary(),
    scores: [integer()],
    label: binary(),
    encoding: Bio.IO.FastQ.quality_encoding()
  }
  ```
  """
  defstruct scoring_characters: "",
            scores: '',
            label: "",
            encoding: :phred_33

  @doc false
  def new(bin, opts \\ []) do
    label = Keyword.get(opts, :label, "")
    encoding = Keyword.get(opts, :encoding)

    %__MODULE__{
      scoring_characters: bin,
      scores: parse_scores(bin, encoding),
      label: label,
      encoding: encoding
    }
  end

  defp parse_scores(bin, :phred_33) do
    offset = 33

    bin
    |> String.to_charlist()
    |> Enum.map(&(&1 - offset))
  end

  defp parse_scores(bin, :phred_64) do
    offset = 64

    bin
    |> String.to_charlist()
    |> Enum.map(&(&1 - offset))
  end

  defp parse_scores(bin, :decimal) do
    bin
    |> String.split(" ")
    |> Enum.map(&String.to_integer/1)
  end
end
