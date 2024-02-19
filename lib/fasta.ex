defmodule Bio.IO.Fasta do
  @moduledoc """
  Allow the input/output of FASTA formatted files.

  The FASTA file format is composed of pairs of lines where the pair is
  demarcated by the ">" character. All data proceeding the ">" character
  represents the 'header' of the pair, while the next line after a newline
  represents sequence data.

  Any data after subsequent newlines that are _not_ preceded by a second ">"
  character are assumed to be multi-line data. For example, the following two
  files would be considered equivalent data:

  ```
  # fasta 1
  >header1
  atgcatgca
  ```

  and

  ```
  # fasta 2
  >header1
  atgc
  atgca
  ```

  The FASTA file format does not specify the type of the data in the sequence.
  That means that you can reasonably store RNA, DNA, amino acid, or any other
  sequence using the format. The expectation is that the data is ASCII encoded.

  The methods in this module do support reading into specified types. See
  `read/2` for more details.
  """

  @type header :: String.t()
  @type sequence :: String.t()
  @type read_opts ::
          {:type, any()}
          | {:parse_header, (String.t() -> String.t())}
  @type fasta_data ::
          [String.t()]
          | [struct()]
          | [{header(), sequence()}]
          | %{headers: [header()], sequences: [sequence()]}

  @doc """
  Read a FASTA formatted file

  The `read/2` function returns an error tuple of the content or error code from
  `File.read`. You can use `:file.format_error/1` to get a descriptive string of
  the error.

  You can specify the return type of the contents by using a module which
  implements the `Bio.Sequential` or equivalent behaviour. Specifically the type
  must have a `new/2` function for building the struct.

  The default option for the reader is a special module `Bio.IO.SequenceTuple`, which
  will return the label and sequence as a tuple of raw binary. See
  `Bio.IO.SequenceTuple.new/2` for details.

  ## Options
  - `:type` - The module for the type of struct you wish to have returned. This
  should minimally implement a `new/2` function equivalent to the
  `Bio.Sequential` behaviour. Otherwise the base `Bio.IO.SequenceTuple` is used.
  - `:parse_header` - A callable for parsing the header values of the FASTA
  file. Otherwise identity is used and the header is returned as is.

  ## Examples

      iex>Bio.IO.Fasta.read("test/files/test_1.fasta")
      {:ok, [{"header1", "ataatatgatagtagatagatagtcctatga"}]}

  Or if you want to alter the headers:

      iex>change_header = fn header ->
      ...>  header
      ...>  |> String.replace("1", "_1")
      ...>  |> String.replace("header", "sample")
      ...> end
      ...>Bio.IO.Fasta.read("test/files/test_1.fasta", parse_header: change_header)
      {:ok, [{"sample_1", "ataatatgatagtagatagatagtcctatga"}]}

  Headers aren't really restricted by the FASTA spec. So it's not too hard to
  come up with more complex schemes. For example, let's assume you have
  key/value pairs separated by `|` (pipe) characters, something like

  ``` string
  >sample_name:this thing|accession_id:WP_6549191.1|genus:Escherichia|species:coli
  ```

  could be parsed as such:

      iex> parse_parts = fn header ->
      ...>   header
      ...>   |> String.split("|")
      ...>   |> Enum.reduce(%{}, fn kv_pair, map ->
      ...>     [key, value] = String.split(kv_pair, ":")
      ...>     Map.put(map, key, value)
      ...>   end)
      ...> end
      ...> Bio.IO.Fasta.read("test/files/complex_headers.fasta", parse_header: parse_parts)
      {
       :ok,
       [{
         %{
          "accession_id" => "WP_6549191.1",
          "genus" => "Escherichia",
          "species" => "coli",
          "sample_name" => "this thing",
          },
         "ataatatgatagtagatagatagtcctatga"
       }]
      }
  """
  @spec read(filename :: Path.t(), opts :: [read_opts]) :: {:ok, any()} | {:error, File.posix()}
  def read(filename, opts \\ []) do
    type = Keyword.get(opts, :type, Bio.IO.SequenceTuple)
    h_fn = Keyword.get(opts, :parse_header, & &1)

    case File.read(filename) do
      {:ok, content} ->
        {:ok, parse(content, "", [], :header, type, h_fn)}

      not_ok ->
        not_ok
    end
  end

  @doc """
  Produces the same output as `read!/2`, but presumes that the file contents are
  loaded into a binary.
  """
  def from_binary(contents, opts \\ []) do
    type = Keyword.get(opts, :type, Bio.IO.SequenceTuple)
    h_fn = Keyword.get(opts, :parse_header, & &1)

    {:ok, parse(contents, "", [], :header, type, h_fn)}
  end

  @doc """
  Read a FASTA formatted file

  The same as `read/2`, but will raise a `File.Error` on failure.
  """
  @spec read!(filename :: Path.t(), opts :: [read_opts]) :: any() | no_return()
  def read!(filename, opts \\ []) do
    type = Keyword.get(opts, :type, Bio.IO.SequenceTuple)
    h_fn = Keyword.get(opts, :parse_header, & &1)

    parse(File.read!(filename), "", [], :header, type, h_fn)
  end

  @doc """
  Write a FASTA file using sequence data.

  The data type that this function accepts is varied, and may be one of a number
  of `List`s. Examples of which types are handled:

  List:
  ``` elixir
    # a list of header/sequence tuples
    [{header(), sequence()}, ...]
    # a list of header/sequence implicitly paired
    [header(), sequence(), header(), sequence(), ...]
    # a list of struct()
    [%Bio.Sequence._{}, ...]
  ```

  Where `%Bio.Sequence._{}` indicates any struct of the `Bio.Sequence` module or
  modules implementing the `Bio.Sequential` behaviour.

  It also supports data in a `Map` format:

  ``` elixir
  %{
    headers: [header(), ...],
    sequences: [sequence(), ...]
  }
  ```

  ## Examples
        iex> Fasta.write("/tmp/test_file.fasta", ["header", "sequence", "header2", "sequence2"])
        :ok

  Will return error types in common with `File.write/3`
  """
  @spec write(filename :: Path.t(), data :: fasta_data, [File.mode()]) ::
          :ok | {:error, File.posix()}
  def write(filename, data, modes \\ [])

  def write(filename, {header, sequence}, modes) do
    File.write(filename, ">#{header}\n#{sequence}\n", modes)
  end

  def write(filename, [header, sequence], modes) do
    File.write(filename, ">#{header}\n#{sequence}\n", modes)
  end

  def write(filename, data, modes) when is_list(data) do
    [datum | _] = data

    data =
      if is_binary(datum) do
        data |> Enum.chunk_every(2)
      else
        data
      end

    data
    |> Enum.reduce("", &to_line/2)
    |> then(fn output -> File.write(filename, output, modes) end)
  end

  def write(filename, %{headers: headers, sequences: sequences}, modes) do
    Enum.zip(headers, sequences)
    |> Enum.reduce("", &to_line/2)
    |> then(fn output -> File.write(filename, output, modes) end)
  end

  defp parse(content, value, acc, _ctx, type, header_fn) when content == "" do
    # this will be [seq, header] for all the parsed seqs
    [value | acc]
    |> Enum.chunk_every(2)
    |> Enum.reduce([], fn [seq, header], acc ->
      List.insert_at(acc, 0, apply(type, :new, [seq, [label: header_fn.(header)]]))
    end)
  end

  defp parse(content, value, acc, ctx, type, header_fn) when ctx == :header do
    <<char::binary-size(1), rest::binary>> = content

    case char do
      ">" -> parse(rest, value, acc, :header, type, header_fn)
      c when c in ["\n", "\r"] -> parse(rest, "", [value | acc], :sequence, type, header_fn)
      _ -> parse(rest, value <> char, acc, :header, type, header_fn)
    end
  end

  defp parse(content, value, acc, ctx, type, header_fn) when ctx == :sequence do
    <<char::binary-size(1), rest::binary>> = content

    case char do
      ">" -> parse(rest, "", [value | acc], :header, type, header_fn)
      c when c in ["\n", "\r"] -> parse(rest, value, acc, :sequence, type, header_fn)
      _ -> parse(rest, value <> char, acc, :sequence, type, header_fn)
    end
  end

  defp to_line([header, sequence], acc) do
    acc <> ">#{header}\n#{sequence}\n"
  end

  defp to_line({header, sequence}, acc) do
    acc <> ">#{header}\n#{sequence}\n"
  end

  defp to_line(%_{} = datum, acc) do
    acc <> apply(datum.__struct__, :fasta_line, [datum])
  end
end
