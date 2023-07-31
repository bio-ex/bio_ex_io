defmodule Bio.IO.SequenceTuple do
  @moduledoc """
  This module is a stand-in for reading a line from files into a tuple of
  binaries.

  This module exists to provide default behavior and a reference implementation
  for the `Bio.Sequential` behaviour of the `bio_ex_sequences` package.
  """

  @doc """
  Generate a tuple of label and sequence from reading fasta and fasta like
  formats:

      {<label/header>, <sequence>}

      >header1
      tagctag

      {"header1", "tagctag"}
  """
  def new(sequence, opts \\ []) do
    {Keyword.get(opts, :label), sequence}
  end
end
