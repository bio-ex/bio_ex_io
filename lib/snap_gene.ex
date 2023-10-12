defmodule Bio.IO.SnapGene do
  @moduledoc ~S"""
  Read a SnapGene file

  The file is read into a struct with the following fields:

  ``` elixir
  %Bio.IO.SnapGene{
      sequence: %Bio.Sequence.DnaStrand{},
      circular?: boolean(),
      valid?: boolean(),
      features: tuple()
    }
  ```

  The `circular?` and `sequence` fields are parsed from the DNA packet.

  The `sequence` field is represented by default as a `Bio.Sequence.DnaStrand`,
  but any module that behaves as a `Bio.Behaviours.Sequence` can be used, since
  the `new/2` method is applied to create the struct.

  > #### Error {: .error}
  >
  > No validation is applied to the sequence, so you can force an invalid sequence
  > struct by passing a module for the incorrect sequence.

  The `valid?` property is determined by parsing the SnapGene cookie to ensure that it
  contains the requisite "SnapGene" string.

  > #### Note {: .neutral}
  >
  > The concept of validity has to do with the snap gene file, and not the
  > sequence or any other of the parsed data.

  Features require a bit more explanation, since they are stored in XML. Parsing
  them into a map is certainly a possibility, but it seemed like doing so would
  reduce the ability of a developer to leverage what I am hoping is a lower
  level library than some.

  In the interest of leaving the end user with as much power as possible, this
  method does not attempt to parse the XML stored within the file. Instead, the
  XML is returned to you in the form generated by `:xmerl_scan.string/1`. In
  doing it this way you have access to the entire space of data stored within
  the file, not just a subset that is parsed. This also means that in order to
  query the data, you need to be comfortable composing XPaths. As an example, if
  you have a terminator feature as the first feature and you want to get the
  segment range:

      iex>{:ok, sample} = SnapGene.read("test/snap_gene/sample-e.dna")
      ...>:xmerl_xpath.string('string(/*/Feature[1]/Segment/@range)', sample.features)
      {:xmlObj, :string, '400-750'}

  As another note, this will also require some familiarity with the file type,
  for example whether or not a range is exclusive or inclusive on either end.
  Attempting to access a node that doesn't exist will return an empty array.

      iex>{:ok, sample} = SnapGene.read("test/snap_gene/sample-e.dna")
      ...>:xmerl_xpath.string('string(/*/Feature[1]/Unknown/Path/@range)', sample.features)
      {:xmlObj, :string, []}

  The semantics of this are admittedly odd. But there's not much to be done
  about that.

  The object returned from `:xmerl_xpath.string/[2,3,4]` is a tuple, so
  `Enumerable` isn't implemented for it. You're best off sticking to XPath to
  get the required elements. The counts of things are simple enough to retrieve
  in this way though. For example, if I wanted to know how many Feature Segments
  there were:

      iex>{:ok, sample} = SnapGene.read("test/snap_gene/sample-e.dna")
      ...>:xmerl_xpath.string('count(/*/Feature/Segment)', sample.features)
      {:xmlObj, :number, 2}

  Now it's a simple matter to map over the desired queries to build up some data
  from the XML:

      iex>{:ok, sample} = SnapGene.read("test/snap_gene/sample-e.dna")
      ...>Enum.map(1..2, fn i -> :xmerl_xpath.string('string(/*/Feature[#{i}]/Segment/@range)', sample.features) end)
      [{:xmlObj, :string, '400-750'},{:xmlObj, :string, '161-241'}]

  I cover the basics of using XPath to perform queries in the [Using
  XML](guides/howtos/use_xml_and_xpath.md) guide. I also plan to write a follow
  up guide with further examples of queries, and an explanation of the mapping
  of concepts between the XML and what is parsed from BioPython.
  """
  @sequence 0x00
  @primers 0x05
  @notes 0x06
  @cookie 0x09
  @features 0x0A

  defstruct sequence: nil, circular?: false, valid?: false, features: {}
  # TODO: Look into the available types for XML data

  @doc """
  Read the contents of a SnapGene file.

  Takes a filename and reads the contents into the `%Bio.IO.SnapGene{}` struct.
  Returns an error tuple on failure with the cause from `File.read/1`.

  You can use `:file.format_error/1` to get a descriptive string of the error.
  """
  @spec read(filename :: Path.t(), opts :: keyword()) ::
          {:ok, %__MODULE__{}} | {:error, File.posix()}
  def read(filename, opts \\ []) do
    sequence_module = Keyword.get(opts, :sequence_type, Bio.IO.SequenceTuple)

    case File.read(filename) do
      {:ok, content} -> {:ok, struct(__MODULE__, do_parse(content, %{}, sequence_module))}
      not_ok -> not_ok
    end
  end

  @doc """
  Produces the same output as `read/2`, but presumes that the file contents are
  loaded into a binary.
  """
  @spec from_binary(content :: binary(), opts :: keyword()) :: {:ok, %__MODULE__{}}
  def from_binary(content, opts \\ []) do
    sequence_module = Keyword.get(opts, :sequence_type, Bio.IO.SequenceTuple)

    {:ok, struct(__MODULE__, do_parse(content, %{}, sequence_module))}
  end

  defp do_parse(<<>>, output, _module), do: output

  # A SnapGene file is made of packets, each packet being a Type-Length-Value
  # structure comprising:
  #   - 1 single byte indicating the packet's type;
  #   - 1 big-endian long integer (4 bytes) indicating the length of the
  #     packet's data;
  #   - the actual data.
  # perfect case for binary pattern matching if there ever was one
  # https://en.wikipedia.org/wiki/Type%E2%80%93length%E2%80%93value)
  defp do_parse(data, output, module) do
    <<packet_type::size(8), content::binary>> = data
    <<packet_length::size(32), content::binary>> = content
    <<packet::binary-size(packet_length), content::binary>> = content

    case packet_type do
      @sequence ->
        new_output = Map.merge(output, parse_sequence(packet, module))
        do_parse(content, new_output, module)

      @primers ->
        do_parse(content, Map.merge(output, parse_primers(packet)), module)

      @notes ->
        do_parse(content, Map.merge(output, parse_notes(packet)), module)

      @cookie ->
        do_parse(content, Map.merge(output, parse_cookie(packet)), module)

      @features ->
        new_output = Map.merge(output, parse_features(packet))
        do_parse(content, new_output, module)

      _ ->
        do_parse(content, output, module)
    end
  end

  defp parse_sequence(data, module) do
    <<circular::size(8), rest::binary>> = data
    circular = Bitwise.band(circular, 0x01) == 1

    %{
      sequence: apply(module, :new, [String.downcase(rest), [length: String.length(rest)]]),
      circular?: circular
    }
  end

  defp parse_notes(data), do: %{notes: xml(data)}
  defp parse_features(data), do: %{features: xml(data)}
  defp parse_primers(data), do: %{primers: xml(data)}

  defp parse_cookie(<<check::binary-size(8), _::binary>>) do
    %{valid?: check == "SnapGene"}
  end

  # When reading the XML data, UTF-8 is implicitly used in the test files.
  # Fortunately, at least one of them had multi-code point characters which
  # really didn't want to play nicely with erlang's underlying
  # xmerl_scan.string. I figured out that you can enforce the latin1 encoding
  # which allows you to get a numeric charlist back out. Basically, it looks
  # like Elixir has no issues converting the latin 1 back into the expected
  # characters.
  # So as a hack, I enforce all XML to be read initially as latin1. Doesn't feel
  # great, but it _appears_ to work.
  defp xml(data) do
    {xml_erl, _} =
      data
      |> enforce_latin_1()
      |> String.to_charlist()
      |> :xmerl_scan.string()

    xml_erl
  end

  # NOTE: if you have any insight into a better way to deal with encoding issues
  # here, then I would be happy to hear it. This feels like a wicked hack.
  defp enforce_latin_1(<<"<?xml version=\"1.0\" encoding=", rest::binary>>) do
    ~s[<?xml version="1.0" encoding="latin1"#{rest}]
  end

  defp enforce_latin_1(<<"<?xml version=\"1.0\"", rest::binary>>) do
    ~s[<?xml version="1.0" encoding="latin1"#{rest}]
  end

  defp enforce_latin_1(bin) do
    ~s[<?xml version="1.0" encoding="latin1"?>#{bin}]
  end
end
