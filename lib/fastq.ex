defmodule Bio.IO.FastQ do
  @moduledoc """
  Allow the input of FASTQ formatted files.

  This implementation references the documentation from
  [NCBI](https://www.ncbi.nlm.nih.gov/sra/docs/submitformats/#fastq-files) and
  uses the Phred scoring 33 offset by default when reading quality scores.
  """
  @type quality_encoding :: :phred_33 | :phred_64 | :decimal
  @type read_opts :: {:quality_encoding, quality_encoding()} | {:type, module()}

  alias Bio.QualityScore

  @doc """
  Read a FASTQ formatted file into memory

  The `read/2` function returns an error tuple of the content or error code from
  `File.read`. You can use `:file.format_error/1` to get a descriptive string of
  the error.

  Content is returned as a list of tuples where the first element is a struct of
  the type from the `type` option, and the second element is a
  `Bio.QualityScore`.

  ## Options
  - `type` - The module for the Sequence type that you want the returned value
  in. Defaults to `Bio.IO.SequenceTuple`. Module should implement the `Bio.Sequential`
  behaviour or minimally expose a `new/2` function which is parametrically
  isomorphic.
  - `quality_encoding` - Determines the encoding of the quality scores.
  """
  @spec read(filename :: Path.t(), opts :: [read_opts]) ::
          {:ok, [{struct(), struct()}]} | {:error, File.posix()}
  def read(filename, opts \\ []) do
    # TODO: Can I get this from application configuration?
    type_module = Keyword.get(opts, :type, Bio.IO.SequenceTuple)
    scoring = Keyword.get(opts, :quality_encoding, :phred_33)

    case File.read(filename) do
      {:ok, content} ->
        {
          :ok,
          content
          |> String.trim()
          |> parse("", [], :header, type_module, scoring)
        }

      not_ok ->
        not_ok
    end
  end

  @doc """
  Read a FASTQ formatted file

  The same as `read/2`, but will raise a `File.Error` on failure.
  """
  @spec read!(filename :: Path.t(), opts :: [read_opts]) :: any() | no_return()
  def read!(filename, opts \\ []) do
    type_module = Keyword.get(opts, :type, Bio.IO.SequenceTuple)
    scoring = Keyword.get(opts, :quality_encoding, :phred_33)

    File.read!(filename)
    |> String.trim()
    |> parse("", [], :header, type_module, scoring)
  end

  defp parse("", value, acc, _ctx, type_module, scoring) do
    [value | acc]
    |> Enum.chunk_every(3)
    |> Enum.reduce([], fn [score, seq, label], acc ->
      sequence_struct = apply(type_module, :new, [seq, [label: label]])
      List.insert_at(acc, 0, {sequence_struct, QualityScore.new(score, encoding: scoring)})
    end)
  end

  defp parse(content, value, acc, ctx, type, scoring) when ctx == :header do
    <<char::binary-size(1), rest::binary>> = content

    case char do
      # Skip @ and continue as header
      "@" ->
        parse(rest, value, acc, :header, type, scoring)

      c when c in ["\n", "\r"] ->
        parse(rest, "", [value | acc], :sequence, type, scoring)

      _ ->
        parse(rest, value <> char, acc, :header, type, scoring)
    end
  end

  defp parse(content, value, acc, ctx, type, scoring) when ctx == :sequence do
    <<char::binary-size(1), rest::binary>> = content

    case char do
      # Skip newlines/carriage return
      c when c in ["\n", "\r"] ->
        parse(rest, value, acc, :sequence, type, scoring)

      # Skip plus and send into scoring
      # Slice to remove the remaining newline
      "+" ->
        rest
        |> String.slice(1, byte_size(rest))
        |> parse("", [value | acc], :score, type, scoring)

      _ ->
        parse(rest, value <> char, acc, :sequence, type, scoring)
    end
  end

  defp parse(content, value, acc, ctx, type, scoring) when ctx == :score do
    <<char::binary-size(1), rest::binary>> = content

    case char do
      "\n" -> parse(rest, "", [value | acc], :header, type, scoring)
      _ -> parse(rest, value <> char, acc, :score, type, scoring)
    end
  end
end
